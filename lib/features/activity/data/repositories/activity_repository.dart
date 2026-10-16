import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
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

  DateTime _parseDateTimeToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      String formattedRaw = raw.trim();
      if (!formattedRaw.endsWith('Z') && !formattedRaw.contains('+') && !formattedRaw.contains('-')) {
        formattedRaw = '${formattedRaw}Z';
      }
      final parsed = DateTime.parse(formattedRaw);
      return parsed.toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<ActivityDataPayload> fetchActivityData(DateTime? customDate) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum terautentikasi');
    }

    // 1. Cek Role Admin
    bool isAdmin = false;
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profile != null && profile['role'] != null) {
      final roleStr = profile['role'].toString().toUpperCase();
      isAdmin = (roleStr == 'ADMIN');
    }

    // 2. Fetch Patrols (Ambil kode_patrol asli dari database)
    var patrolQuery = _supabase.from('patrols').select(
          'id, created_by, lokasi, item_5s, deskripsi, tanggal, created_at, finished_at, status, judul, kode_patrol',
        );

    if (!isAdmin) {
      patrolQuery = patrolQuery.eq('created_by', user.id);
    }

    if (customDate != null) {
      final startOfDay = DateTime(customDate.year, customDate.month, customDate.day).toUtc();
      final endOfDay = DateTime(customDate.year, customDate.month, customDate.day, 23, 59, 59).toUtc();
      patrolQuery = patrolQuery
          .gte('tanggal', startOfDay.toIso8601String())
          .lte('tanggal', endOfDay.toIso8601String());
    }

    final List<dynamic> rawPatrolList = await patrolQuery.order('tanggal', ascending: true);

    int done = 0;
    int progress = 0;
    int openCount = 0;
    List<CompletedPatrolModel> doneList = [];
    List<Map<String, dynamic>> processedPatrols = [];
    
    // Map untuk mencocokkan ID Patrol dengan kode_patrol
    Map<String, String> patrolCodeMap = {};

    for (int i = 0; i < rawPatrolList.length; i++) {
      final p = rawPatrolList[i];
      final st = (p['status'] as String? ?? '').trim().toUpperCase();

      final rawTanggalStr = (p['tanggal'] ?? p['created_at'])?.toString();
      final DateTime patrolDateTime = _parseDateTimeToLocal(rawTanggalStr);

      // Utamakan kode_patrol dari database Supabase
      final String actualCode = (p['kode_patrol']?.toString().isNotEmpty ?? false)
          ? p['kode_patrol'].toString().replaceAll('SK-', 'NP-')
          : 'NP-${patrolDateTime.year}-${(i + 1).toString().padLeft(4, '0')}';

      final String patrolId = p['id']?.toString() ?? '';
      if (patrolId.isNotEmpty) {
        patrolCodeMap[patrolId] = actualCode;
      }

      final lokasiName = (p['lokasi']?.toString().isNotEmpty ?? false)
          ? p['lokasi'].toString()
          : 'Maintenance Area';

      if (st == 'CLOSED' || st == 'COMPLETED' || st == 'SELESAI') {
        done++;
        final rawFinishedAtStr = (p['finished_at'] ?? p['tanggal'] ?? p['created_at'])?.toString();
        final dtFinished = _parseDateTimeToLocal(rawFinishedAtStr);
        final formattedFinishedDate = DateFormat('dd MMM yyyy, HH:mm').format(dtFinished);

        doneList.add(
          CompletedPatrolModel(
            locationName: lokasiName,
            finishedAt: formattedFinishedDate,
          ),
        );
      } else if (st == 'IN PROGRESS' || st == 'IN_PROGRESS' || st == 'PROSES') {
        progress++;
      } else if (st == 'OPEN' || st == 'PENDING') {
        openCount++;
      }

      processedPatrols.add({
        ...p,
        'display_code': actualCode,
        'lokasi_clean': lokasiName,
        'date_time': patrolDateTime,
      });
    }

    final stats = ActivityStatModel(
      total: rawPatrolList.length,
      selesai: done,
      inProgress: progress,
      open: openCount,
    );

    processedPatrols = processedPatrols.reversed.toList();

    // 3. Fetch Activity Logs
    List<ActivityLogModel> todayList = [];
    List<ActivityLogModel> yesterdayList = [];

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    var logsQuery = _supabase.from('activity_logs').select().eq('user_id', user.id);
    final List<dynamic> logList = await logsQuery.order('created_at', ascending: false).limit(30);

    if (logList.isNotEmpty) {
      for (var log in logList) {
        final createdAtStr = log['created_at']?.toString();
        if (createdAtStr == null) continue;

        final createdAt = _parseDateTimeToLocal(createdAtStr);
        final logDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        final timeFormatted = DateFormat('HH:mm').format(createdAt);

        // Sisipkan kode_patrol presisi dari database berdasarkan record_id
        final recordId = log['record_id']?.toString() ?? '';
        final mapData = Map<String, dynamic>.from(log);
        
        if (patrolCodeMap.containsKey(recordId)) {
          mapData['kode_patrol'] = patrolCodeMap[recordId];
        } else if (processedPatrols.isNotEmpty) {
          mapData['kode_patrol'] = processedPatrols.first['display_code'];
        }

        final item = ActivityLogModel.fromMap(mapData, timeFormatted);

        if (logDate.isAtSameMomentAs(todayDate)) {
          todayList.add(item);
        } else if (logDate.isAtSameMomentAs(yesterdayDate)) {
          yesterdayList.add(item);
        } else {
          todayList.add(item);
        }
      }
    } else {
      // Fallback log jika tabel activity_logs kosong
      for (var p in processedPatrols) {
        final DateTime patrolDateTime = p['date_time'];
        final logDate = DateTime(patrolDateTime.year, patrolDateTime.month, patrolDateTime.day);
        final timeFormatted = DateFormat('HH:mm').format(patrolDateTime);

        final String lokasiName = p['lokasi_clean'];
        final String codeName = p['display_code'];

        final st = (p['status'] as String? ?? '').trim().toUpperCase();
        final isClosed = st == 'CLOSED' || st == 'COMPLETED' || st == 'SELESAI';

        final item = ActivityLogModel(
          action: isClosed ? 'Patroli Selesai' : 'Membuat Patroli Baru',
          code: codeName,
          location: lokasiName,
          time: timeFormatted,
          status: p['status']?.toString() ?? 'OPEN',
          createdAt: patrolDateTime,
          icon: isClosed ? Icons.check_circle_rounded : Icons.add_task_rounded,
          iconColor: isClosed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
          iconBgColor: isClosed ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
        );

        if (logDate.isAtSameMomentAs(todayDate)) {
          todayList.add(item);
        } else if (logDate.isAtSameMomentAs(yesterdayDate)) {
          yesterdayList.add(item);
        } else {
          todayList.add(item);
        }
      }
    }

    // 4. Fetch Schedules
    List<ScheduleItemModel> loadedSchedules = [];
    try {
      final schedulesRes = await _supabase
          .from('schedules')
          .select('id, title, description, start_date')
          .order('start_date', ascending: false)
          .limit(10);

      for (var s in schedulesRes) {
        loadedSchedules.add(
          ScheduleItemModel(
            title: s['title'] ?? 'Jadwal Patrol 5S',
            date: s['start_date'] ?? '-',
            location: s['description'] ?? 'Area Pabrik',
          ),
        );
      }
    } catch (_) {}

    return ActivityDataPayload(
      isAdmin: isAdmin,
      stats: stats,
      logsToday: todayList,
      logsYesterday: yesterdayList,
      completedPatrols: doneList,
      schedules: loadedSchedules,
    );
  }
}