// lib/features/activity/data/repositories/activity_repository.dart
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../models/activity_stat_model.dart';
import '../models/completed_patrol_model.dart';
import '../models/schedule_item_model.dart';

class ActivityDataPayload {
  final bool isAdmin;
  final ActivityStatModel stats;
  final List<ActivityLogModel> logsToday;
  final List<ActivityLogModel> logsYesterday;
  final List<CompletedPatrolModel> completedPatrols;
  final List<ScheduleItemModel> schedules;

  ActivityDataPayload({
    required this.isAdmin,
    required this.stats,
    required this.logsToday,
    required this.logsYesterday,
    required this.completedPatrols,
    required this.schedules,
  });
}

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Memproses string timestamp ISO/UTC dari Supabase ke DateTime lokal (WIB/UTC+7)
  DateTime _parseDateTimeToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      String formattedRaw = raw.trim();
      if (!formattedRaw.endsWith('Z') && !formattedRaw.contains('+') && !formattedRaw.contains('-')) {
        formattedRaw = '${formattedRaw}Z';
      }
      return DateTime.parse(formattedRaw).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<ActivityDataPayload> fetchActivityData({
    int selectedMonth = 0, // 0 = Semua Bulan
    int selectedYear = 0,  // 0 = Semua Tahun
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

    final String userRole = profile?['role']?.toString().toUpperCase() ?? 'STAFF_INTERNSHIP';
    final String? myArea = profile?['area_responsibility']?.toString();
    final bool isAdmin = (userRole == 'ADMIN');

    // 2. Query Tabel Patrols (Untuk Statistik Dashboard Activity)
    var patrolQuery = _supabase.from('patrols').select();

    // Saring Data Patrol Berdasarkan Hak Akses Role
    if (userRole == 'PIC_AREA' && myArea != null && myArea.isNotEmpty) {
      patrolQuery = patrolQuery.or('created_by.eq.${user.id},lokasi.eq.$myArea');
    } else if (userRole == 'STAFF_AHLI' || userRole == 'STAFF_INTERNSHIP') {
      patrolQuery = patrolQuery.eq('created_by', user.id);
    }

    // Saring Berdasarkan Filter Bulan dan Tahun
    if (selectedYear > 0) {
      final mStart = selectedMonth > 0 ? selectedMonth : 1;
      final mEnd = selectedMonth > 0 ? selectedMonth : 12;

      final startDate = DateTime(selectedYear, mStart, 1).toIso8601String();
      final endDate = DateTime(selectedYear, mEnd + 1, 0, 23, 59, 59).toIso8601String();

      patrolQuery = patrolQuery.gte('created_at', startDate).lte('created_at', endDate);
    }

    final List<dynamic> rawPatrolList = await patrolQuery.order('created_at', ascending: false);

    int done = 0;
    int progress = 0;
    int openCount = 0;
    List<CompletedPatrolModel> doneList = [];
    Map<String, Map<String, dynamic>> patrolMap = {};

    for (int i = 0; i < rawPatrolList.length; i++) {
      final p = Map<String, dynamic>.from(rawPatrolList[i]);
      final st = (p['status'] as String? ?? '').trim().toUpperCase();

      final rawTanggalStr = (p['created_at'] ?? p['tanggal'])?.toString();
      final DateTime patrolDateTime = _parseDateTimeToLocal(rawTanggalStr);

      final String actualCode = (p['kode_patrol']?.toString().isNotEmpty ?? false)
          ? p['kode_patrol'].toString().replaceAll('SK-', 'NP-')
          : 'NP-${patrolDateTime.year}-${(i + 1).toString().padLeft(4, '0')}';

      p['kode_patrol'] = actualCode;
      p['lokasi_clean'] = (p['lokasi']?.toString().isNotEmpty ?? false) ? p['lokasi'].toString() : 'Area Pabrik';
      p['date_time'] = patrolDateTime;

      final String patrolId = p['id']?.toString() ?? '';
      if (patrolId.isNotEmpty) {
        patrolMap[patrolId] = p;
      }

      if (st == 'CLOSED' || st == 'COMPLETED' || st == 'SELESAI') {
        done++;
        final rawFinishedAtStr = (p['finished_at'] ?? p['created_at'])?.toString();
        final dtFinished = _parseDateTimeToLocal(rawFinishedAtStr);

        doneList.add(
          CompletedPatrolModel(
            locationName: p['lokasi_clean'],
            finishedAt: DateFormat('dd/MM/yy HH:mm').format(dtFinished),
            rawPatrolData: p,
          ),
        );
      } else if (st == 'IN PROGRESS' || st == 'IN_PROGRESS' || st == 'PROSES') {
        progress++;
      } else if (st == 'OPEN' || st == 'PENDING') {
        openCount++;
      }
    }

    final stats = ActivityStatModel(
      total: rawPatrolList.length,
      selesai: done,
      inProgress: progress,
      open: openCount,
    );

    // 3. Query Activity Logs
    var logsQuery = _supabase.from('activity_logs').select();

    // Saring log berdasarkan role:
    // - Admin: Semua Log
    // - PIC_AREA: Log user sendiri ATAU log lokasi di area_responsibility
    // - Staff Ahli & Internship: Log diri sendiri saja
    if (userRole == 'PIC_AREA' && myArea != null && myArea.isNotEmpty) {
      logsQuery = logsQuery.or('user_id.eq.${user.id},area_location.eq.$myArea');
    } else if (userRole == 'STAFF_AHLI' || userRole == 'STAFF_INTERNSHIP') {
      logsQuery = logsQuery.eq('user_id', user.id);
    }

    // Filter tanggal log
    if (selectedYear > 0) {
      final mStart = selectedMonth > 0 ? selectedMonth : 1;
      final mEnd = selectedMonth > 0 ? selectedMonth : 12;

      final startDate = DateTime(selectedYear, mStart, 1).toIso8601String();
      final endDate = DateTime(selectedYear, mEnd + 1, 0, 23, 59, 59).toIso8601String();

      logsQuery = logsQuery.gte('created_at', startDate).lte('created_at', endDate);
    }

    final List<dynamic> logList = await logsQuery.order('created_at', ascending: false).limit(100);
    List<ActivityLogModel> logsList = [];
    Set<String> processedRecordIds = {};

    for (var log in logList) {
      final recordId = log['record_id']?.toString() ?? log['id']?.toString() ?? '';

      if (recordId.isNotEmpty && processedRecordIds.contains(recordId)) {
        continue;
      }
      if (recordId.isNotEmpty) {
        processedRecordIds.add(recordId);
      }

      final createdAtStr = log['created_at']?.toString();
      if (createdAtStr == null) continue;

      final createdAt = _parseDateTimeToLocal(createdAtStr);
      final timeFormatted = DateFormat('dd/MM/yy HH:mm').format(createdAt);
      final linkedPatrol = patrolMap[recordId];

      logsList.add(ActivityLogModel.fromMap(
        Map<String, dynamic>.from(log),
        timeFormatted,
        rawPatrolData: linkedPatrol,
      ));
    }

    return ActivityDataPayload(
      isAdmin: isAdmin,
      stats: stats,
      logsToday: logsList,
      logsYesterday: [],
      completedPatrols: doneList,
      schedules: [],
    );
  }
}