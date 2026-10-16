import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_filter_model.dart';
import '../models/dashboard_data_model.dart';
import '../models/trend_chart_model.dart';
import '../models/summary_stat_model.dart';
import '../models/status_donut_model.dart';
import '../models/notification_item_model.dart';

class DashboardRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String>> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'name': 'Guest User', 'dept': 'DEPARTEMEN TIDAK DIKETAHUI', 'initials': 'GU'};
      }

      final response = await _supabase
          .from('profiles')
          .select('full_name, departments(name)')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return {'name': 'User', 'dept': '-', 'initials': 'U'};
      }

      final String fullName = response['full_name'] as String? ?? 'User';
      String deptName = '-';
      if (response['departments'] != null && response['departments']['name'] != null) {
        deptName = response['departments']['name'] as String;
      }

      final nameParts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
      String initials = 'U';
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty) {
        initials = nameParts[0][0].toUpperCase();
      }

      return {
        'name': fullName,
        'dept': deptName.toUpperCase(),
        'initials': initials,
      };
    } catch (_) {
      return {'name': 'User', 'dept': '-', 'initials': 'U'};
    }
  }

  /// Mengambil daftar notifikasi pengguna dari Supabase
  Future<List<NotificationItemModel>> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('id, title, message, type, is_read, reference_id, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      return (response as List)
          .map((e) => NotificationItemModel.fromMap(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil jumlah notifikasi yang BELUM DIBACA (is_read = false)
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Tandai notifikasi sebagai terbaca
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<DashboardDataModel> fetchDashboardData(DashboardFilterModel filter) async {
    try {
      // 1. Tentukan Tahun yang Digunakan
      int activeYear = filter.year != 'ALL' ? int.parse(filter.year) : DateTime.now().year;

      DateTime startDate;
      DateTime endDate;

      bool isSingleMonth = filter.month != 'ALL';
      int? targetMonth = isSingleMonth ? int.parse(filter.month) : null;

      if (isSingleMonth) {
        startDate = DateTime.utc(activeYear, targetMonth!, 1).subtract(const Duration(hours: 7));
        final lastDay = DateTime.utc(activeYear, targetMonth + 1, 0, 23, 59, 59);
        endDate = lastDay.subtract(const Duration(hours: 7));
      } else {
        startDate = DateTime.utc(activeYear, 1, 1).subtract(const Duration(hours: 7));
        endDate = DateTime.utc(activeYear, 12, 31, 23, 59, 59).subtract(const Duration(hours: 7));
      }

      // Query data berdasarkan rentang waktu
      dynamic query = _supabase.from('patrols').select('id, status, tanggal, created_at, started_at, finished_at');
      query = query
          .gte('tanggal', startDate.toIso8601String())
          .lte('tanggal', endDate.toIso8601String());

      final List<dynamic> response = await query;
      final List<Map<String, dynamic>> patrols = List<Map<String, dynamic>>.from(response);

      // 2. Kalkulasi Status Donut
      int donutOpen = 0;
      int donutInProgress = 0;
      int donutClosed = 0;

      for (var p in patrols) {
        final status = p['status']?.toString().toUpperCase() ?? '';
        if (status == 'CLOSED' || p['finished_at'] != null) {
          donutClosed++;
        } else if (status == 'IN_PROGRESS' || p['started_at'] != null) {
          donutInProgress++;
        } else {
          donutOpen++;
        }
      }

      final donutData = StatusDonutData(
        open: donutOpen,
        inProgress: donutInProgress,
        closed: donutClosed,
      );

      // 3. Kalkulasi Trend Line Chart (Dengan pemotongan titik akhir sesuai data terbaru)
      List<TrendPoint> trendPoints = [];

      if (!isSingleMonth) {
        // TAMPILKAN BULANAN (Jan - Des) - Disesuaikan dengan data terbaru
        final List<String> monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        Map<int, Map<String, int>> monthlyCounts = {
          for (int m = 1; m <= 12; m++) m: {'open': 0, 'in_progress': 0, 'closed': 0}
        };

        int maxMonthWithData = 1; // Default minimal Januari

        for (var p in patrols) {
          final month = _registerEventMonthly(monthlyCounts, p['tanggal'] ?? p['created_at'], p);
          if (month != null && month > maxMonthWithData) {
            maxMonthWithData = month;
          }
        }

        // Jika tahun berjalan, pastikan menampilkan hingga bulan saat ini jika bulan saat ini lebih besar dari data
        final now = DateTime.now();
        if (activeYear == now.year && now.month > maxMonthWithData) {
          maxMonthWithData = now.month;
        }

        // Hanya tambahkan titik hingga bulan max yang ada datanya / bulan saat ini
        for (int m = 1; m <= maxMonthWithData; m++) {
          trendPoints.add(TrendPoint(
            label: monthLabels[m - 1],
            openCount: monthlyCounts[m]!['open']!,
            inProgressCount: monthlyCounts[m]!['in_progress']!,
            closedCount: monthlyCounts[m]!['closed']!,
          ));
        }
      } else {
        // TAMPILKAN PEKANAN (W1 - W5) - Disesuaikan dengan pekan terbaru
        Map<int, Map<String, int>> weeklyCounts = {
          for (int w = 1; w <= 5; w++) w: {'open': 0, 'in_progress': 0, 'closed': 0}
        };

        int maxWeekWithData = 1;

        for (var p in patrols) {
          final week = _registerEventWeekly(weeklyCounts, p['tanggal'] ?? p['created_at'], p);
          if (week != null && week > maxWeekWithData) {
            maxWeekWithData = week;
          }
        }

        for (int w = 1; w <= maxWeekWithData; w++) {
          trendPoints.add(TrendPoint(
            label: 'W$w',
            openCount: weeklyCounts[w]!['open']!,
            inProgressCount: weeklyCounts[w]!['in_progress']!,
            closedCount: weeklyCounts[w]!['closed']!,
          ));
        }
      }

      // 4. Kalkulasi Ringkasan Status
      int totalTemuanTahunIni = 0;
      int highestCount = -1;
      String highestLabel = '-';
      int lowestCount = 999999;
      String lowestLabel = '-';
      int activePeriodsCount = 0;

      for (var pt in trendPoints) {
        final totalPeriodVal = pt.openCount + pt.inProgressCount + pt.closedCount;

        if (totalPeriodVal > 0) {
          totalTemuanTahunIni += totalPeriodVal;
          activePeriodsCount++;

          if (totalPeriodVal > highestCount) {
            highestCount = totalPeriodVal;
            highestLabel = pt.label;
          }

          if (totalPeriodVal < lowestCount) {
            lowestCount = totalPeriodVal;
            lowestLabel = pt.label;
          }
        }
      }

      if (activePeriodsCount == 0) {
        highestCount = 0;
        lowestCount = 0;
      }

      final double avgPerPeriod = activePeriodsCount > 0 
          ? (totalTemuanTahunIni / activePeriodsCount) 
          : 0.0;

      final summaryStats = SummaryStatModel(
        averagePerPeriod: avgPerPeriod,
        highestPeriod: highestLabel,
        highestCount: highestCount < 0 ? 0 : highestCount,
        lowestPeriod: lowestLabel,
        lowestCount: lowestCount == 999999 ? 0 : lowestCount,
        totalCount: totalTemuanTahunIni,
        isMonthlyFilter: isSingleMonth,
      );

      return DashboardDataModel(
        trendPoints: trendPoints,
        summaryStats: summaryStats,
        donutData: donutData,
      );
    } catch (e) {
      rethrow;
    }
  }

  int? _registerEventMonthly(Map<int, Map<String, int>> monthlyCounts, String? dateStr, Map<String, dynamic> item) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dt = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 7));
      final month = dt.month;

      if (monthlyCounts.containsKey(month)) {
        final status = item['status']?.toString().toUpperCase() ?? '';
        if (status == 'CLOSED' || item['finished_at'] != null) {
          monthlyCounts[month]!['closed'] = monthlyCounts[month]!['closed']! + 1;
        } else if (status == 'IN_PROGRESS' || item['started_at'] != null) {
          monthlyCounts[month]!['in_progress'] = monthlyCounts[month]!['in_progress']! + 1;
        } else {
          monthlyCounts[month]!['open'] = monthlyCounts[month]!['open']! + 1;
        }
        return month;
      }
    } catch (_) {}
    return null;
  }

  int? _registerEventWeekly(Map<int, Map<String, int>> weeklyCounts, String? dateStr, Map<String, dynamic> item) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dt = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 7));
      final day = dt.day;

      int weekIndex = ((day - 1) ~/ 7) + 1;
      if (weekIndex > 5) weekIndex = 5;

      if (weeklyCounts.containsKey(weekIndex)) {
        final status = item['status']?.toString().toUpperCase() ?? '';
        if (status == 'CLOSED' || item['finished_at'] != null) {
          weeklyCounts[weekIndex]!['closed'] = weeklyCounts[weekIndex]!['closed']! + 1;
        } else if (status == 'IN_PROGRESS' || item['started_at'] != null) {
          weeklyCounts[weekIndex]!['in_progress'] = weeklyCounts[weekIndex]!['in_progress']! + 1;
        } else {
          weeklyCounts[weekIndex]!['open'] = weeklyCounts[weekIndex]!['open']! + 1;
        }
        return weekIndex;
      }
    } catch (_) {}
    return null;
  }
}