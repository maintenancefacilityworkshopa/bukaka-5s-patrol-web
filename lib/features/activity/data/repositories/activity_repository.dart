// lib/features/activity/data/repositories/activity_repository.dart
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../models/activity_stat_model.dart';
import '../models/completed_patrol_model.dart';
import '../models/location_ranking_model.dart';
import '../models/schedule_item_model.dart';

class ActivityDataPayload {
  final bool isAdmin;
  final List<String> availableLocations;
  final ActivityStatModel stats;
  final List<ActivityLogModel> logsToday;
  final List<ActivityLogModel> logsYesterday;
  final List<CompletedPatrolModel> completedPatrols;
  final List<LocationRankingModel> locationRankings;
  final List<ScheduleItemModel> schedules;

  ActivityDataPayload({
    required this.isAdmin,
    required this.availableLocations,
    required this.stats,
    required this.logsToday,
    required this.logsYesterday,
    required this.completedPatrols,
    required this.locationRankings,
    required this.schedules,
  });
}

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  DateTime _parseDateTimeToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      String formattedRaw = raw.trim();
      if (!formattedRaw.endsWith('Z') &&
          !formattedRaw.contains('+') &&
          !formattedRaw.contains('-')) {
        formattedRaw = '${formattedRaw}Z';
      }
      return DateTime.parse(formattedRaw).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Normalisasi nama lokasi agar variasi seperti "Stockyard Material KPS" & "Stockyard Material & KPS" tetap cocok
  String _normalizeLocation(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isLocationMatch(String targetFilter, String candidateLocation) {
    if (targetFilter == 'Semua Lokasi' || targetFilter.isEmpty) return true;
    final normTarget = _normalizeLocation(targetFilter);
    final normCandidate = _normalizeLocation(candidateLocation);
    return normCandidate == normTarget ||
        normCandidate.contains(normTarget) ||
        normTarget.contains(normCandidate);
  }

  Future<ActivityDataPayload> fetchActivityData({
    int selectedMonth = 0, // 0 = Semua Bulan
    int selectedYear = 0, // 0 = Semua Tahun
    String selectedLocation = 'Semua Lokasi',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum terautentikasi');
    }

    // 1. Ambil Profile Pengguna (Role & Area Responsibility)
    final profile = await _supabase
        .from('profiles')
        .select('role, area_responsibility')
        .eq('id', user.id)
        .maybeSingle();

    final String userRole =
        profile?['role']?.toString().toUpperCase() ?? 'STAFF_INTERNSHIP';
    final String? myArea = profile?['area_responsibility']?.toString();
    final bool isAdmin = (userRole == 'ADMIN' || userRole == 'ADMINISTRATOR');

    // 2. Ambil Daftar Master Locations dari Supabase
    final List<Map<String, dynamic>> masterLocations = [];
    try {
      final locResponse = await _supabase
          .from('locations')
          .select('id, code, name, description, display_order')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      for (final item in (locResponse as List<dynamic>)) {
        masterLocations.add(Map<String, dynamic>.from(item as Map));
      }
    } catch (_) {}

    final List<String> availableLocations = masterLocations
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();

    // 3. Query Tabel Patrols (Untuk Statistik, Selesai, Open, dan Peringkat Location)
    var patrolQuery = _supabase.from('patrols').select();

    // Saring Data Patrol Berdasarkan Hak Akses Role
    if (!isAdmin) {
      if (userRole == 'PIC_AREA' && myArea != null && myArea.isNotEmpty) {
        patrolQuery =
            patrolQuery.or('created_by.eq.${user.id},lokasi.eq.$myArea');
      } else if (userRole == 'STAFF_AHLI' || userRole == 'STAFF_INTERNSHIP') {
        patrolQuery = patrolQuery.eq('created_by', user.id);
      }
    }

    // Saring Berdasarkan Filter Bulan dan Tahun
    if (selectedYear > 0) {
      final mStart = selectedMonth > 0 ? selectedMonth : 1;
      final mEnd = selectedMonth > 0 ? selectedMonth : 12;

      final startDate = DateTime(selectedYear, mStart, 1).toIso8601String();
      final endDate =
          DateTime(selectedYear, mEnd + 1, 0, 23, 59, 59).toIso8601String();

      patrolQuery =
          patrolQuery.gte('created_at', startDate).lte('created_at', endDate);
    }

    final List<dynamic> rawPatrolList =
        await patrolQuery.order('created_at', ascending: false);

    // Siapkan peta kalkulasi peringkat lokasi (diambil dari seluruh data periode aktif)
    final Map<String, Map<String, dynamic>> rankingAccumulator = {};
    for (final loc in masterLocations) {
      final locName = (loc['name'] ?? '').toString().trim();
      final locDesc = (loc['description'] ?? '').toString().trim();
      if (locName.isNotEmpty) {
        rankingAccumulator[locName] = {
          'name': locName,
          'description': locDesc,
          'total': 0,
          'open': 0,
          'in_progress': 0,
          'closed': 0,
        };
      }
    }

    int totalFilteredPatrol = 0;
    int done = 0;
    int progress = 0;
    int openCount = 0;
    final List<CompletedPatrolModel> doneList = [];
    final Map<String, Map<String, dynamic>> patrolMap = {};

    for (int i = 0; i < rawPatrolList.length; i++) {
      final p = Map<String, dynamic>.from(rawPatrolList[i] as Map);
      final st = (p['status'] as String? ?? '').trim().toUpperCase();

      final rawTanggalStr = (p['created_at'] ?? p['tanggal'])?.toString();
      final DateTime patrolDateTime = _parseDateTimeToLocal(rawTanggalStr);

      final String actualCode =
          (p['kode_patrol']?.toString().isNotEmpty ?? false)
              ? p['kode_patrol'].toString().replaceAll('SK-', 'NP-')
              : 'NP-${patrolDateTime.year}-${(i + 1).toString().padLeft(4, '0')}';

      final String rawLocStr =
          (p['lokasi'] ?? p['location'] ?? '').toString().trim();
      final String cleanLoc = rawLocStr.isNotEmpty ? rawLocStr : 'Area Pabrik';

      p['kode_patrol'] = actualCode;
      p['lokasi_clean'] = cleanLoc;
      p['date_time'] = patrolDateTime;

      final String patrolId = p['id']?.toString() ?? '';
      if (patrolId.isNotEmpty) {
        patrolMap[patrolId] = p;
      }

      // Akumulasi untuk Peringkat Location (Admin) pada periode Bulan/Tahun terpilih
      for (final entry in rankingAccumulator.entries) {
        if (_isLocationMatch(entry.key, cleanLoc)) {
          entry.value['total'] = (entry.value['total'] as int) + 1;
          if (st == 'CLOSED' || st == 'COMPLETED' || st == 'SELESAI') {
            entry.value['closed'] = (entry.value['closed'] as int) + 1;
          } else if (st == 'IN PROGRESS' ||
              st == 'IN_PROGRESS' ||
              st == 'PROSES') {
            entry.value['in_progress'] =
                (entry.value['in_progress'] as int) + 1;
          } else {
            entry.value['open'] = (entry.value['open'] as int) + 1;
          }
          break;
        }
      }

      // Filter Statistik Card Ringkasan & Daftar Selesai berdasarkan selectedLocation
      if (!_isLocationMatch(selectedLocation, cleanLoc)) {
        continue;
      }

      totalFilteredPatrol++;

      if (st == 'CLOSED' || st == 'COMPLETED' || st == 'SELESAI') {
        done++;
        final rawFinishedAtStr =
            (p['finished_at'] ?? p['created_at'])?.toString();
        final dtFinished = _parseDateTimeToLocal(rawFinishedAtStr);

        doneList.add(
          CompletedPatrolModel(
            locationName: cleanLoc,
            finishedAt: DateFormat('dd/MM/yy HH:mm').format(dtFinished),
            rawPatrolData: p,
          ),
        );
      } else if (st == 'IN PROGRESS' ||
          st == 'IN_PROGRESS' ||
          st == 'PROSES') {
        progress++;
      } else if (st == 'OPEN' || st == 'PENDING') {
        openCount++;
      }
    }

    // Susun & Urutkan Peringkat Location dari Total Patrol Terbanyak ke Paling Sedikit
    final sortedRankingValues = rankingAccumulator.values.toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    final List<LocationRankingModel> locationRankings = [];
    for (int i = 0; i < sortedRankingValues.length; i++) {
      final item = sortedRankingValues[i];
      locationRankings.add(
        LocationRankingModel(
          rank: i + 1,
          locationName: item['name'] as String,
          locationDescription: item['description'] as String,
          totalPatrol: item['total'] as int,
          openCount: item['open'] as int,
          inProgressCount: item['in_progress'] as int,
          closedCount: item['closed'] as int,
        ),
      );
    }

    final stats = ActivityStatModel(
      total: totalFilteredPatrol,
      selesai: done,
      inProgress: progress,
      open: openCount,
    );

    // 4. Query Activity Logs
    var logsQuery = _supabase.from('activity_logs').select();

    if (!isAdmin) {
      if (userRole == 'PIC_AREA' && myArea != null && myArea.isNotEmpty) {
        logsQuery =
            logsQuery.or('user_id.eq.${user.id},area_location.eq.$myArea');
      } else if (userRole == 'STAFF_AHLI' || userRole == 'STAFF_INTERNSHIP') {
        logsQuery = logsQuery.eq('user_id', user.id);
      }
    }

    if (selectedYear > 0) {
      final mStart = selectedMonth > 0 ? selectedMonth : 1;
      final mEnd = selectedMonth > 0 ? selectedMonth : 12;

      final startDate = DateTime(selectedYear, mStart, 1).toIso8601String();
      final endDate =
          DateTime(selectedYear, mEnd + 1, 0, 23, 59, 59).toIso8601String();

      logsQuery =
          logsQuery.gte('created_at', startDate).lte('created_at', endDate);
    }

    final List<dynamic> logList =
        await logsQuery.order('created_at', ascending: false).limit(150);
    final List<ActivityLogModel> logsList = [];
    final Set<String> processedRecordIds = {};

    for (var log in logList) {
      final recordId =
          log['record_id']?.toString() ?? log['id']?.toString() ?? '';

      if (recordId.isNotEmpty && processedRecordIds.contains(recordId)) {
        continue;
      }

      final logArea = (log['area_location'] ?? '').toString().trim();
      final linkedPatrol = patrolMap[recordId];
      final effectiveLoc = logArea.isNotEmpty
          ? logArea
          : (linkedPatrol?['lokasi_clean']?.toString() ?? '');

      // Saring log berdasarkan Filter Lokasi yang dipilih
      if (!_isLocationMatch(selectedLocation, effectiveLoc)) {
        continue;
      }

      if (recordId.isNotEmpty) {
        processedRecordIds.add(recordId);
      }

      final createdAtStr = log['created_at']?.toString();
      if (createdAtStr == null) continue;

      final createdAt = _parseDateTimeToLocal(createdAtStr);
      final timeFormatted = DateFormat('dd/MM/yy HH:mm').format(createdAt);

      logsList.add(ActivityLogModel.fromMap(
        Map<String, dynamic>.from(log as Map),
        timeFormatted,
        rawPatrolData: linkedPatrol,
      ));
    }

    return ActivityDataPayload(
      isAdmin: isAdmin,
      availableLocations: availableLocations,
      stats: stats,
      logsToday: logsList,
      logsYesterday: [],
      completedPatrols: doneList,
      locationRankings: locationRankings,
      schedules: [],
    );
  }
}
