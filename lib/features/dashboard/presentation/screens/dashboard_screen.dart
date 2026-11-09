import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/dashboard_filter_model.dart';
import '../../data/models/dashboard_data_model.dart';
import '../../data/models/notification_item_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_notification_list.dart';
import '../widgets/ringkasan_status_cards.dart';
import '../widgets/status_donut_chart.dart';
import '../widgets/trend_temuan_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardRepository _repository = DashboardRepository();

  DashboardFilterModel _filter = const DashboardFilterModel();
  bool _isLoading = true;
  String? _errorMessage;

  DashboardDataModel? _dashboardData;
  List<NotificationItemModel> _notifications = [];
  int _unreadCount = 0;

  String? _userName;
  String? _userDepartment;
  String? _userInitials;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _repository.getUserProfile();
      final dashboardFuture = _repository.fetchDashboardData(_filter);
      final notificationFuture = _repository.getNotifications();
      final unreadCountFuture = _repository.getUnreadNotificationCount();

      final results = await Future.wait([
        profileFuture,
        dashboardFuture,
        notificationFuture,
        unreadCountFuture,
      ]);

      final profileData = results[0] as Map<String, String>;
      final dashboardData = results[1] as DashboardDataModel;
      final notificationData = results[2] as List<NotificationItemModel>;
      final unreadCount = results[3] as int;

      if (mounted) {
        setState(() {
          _userName = profileData['name'];
          _userDepartment = profileData['dept'];
          _userInitials = profileData['initials'];
          _dashboardData = dashboardData;
          _notifications = notificationData;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data dashboard';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged(DashboardFilterModel updatedFilter) {
    setState(() {
      _filter = updatedFilter;
    });
    _fetchData();
  }

  Future<void> _handleNotificationTap(NotificationItemModel notification) async {
    if (!notification.isRead) {
      await _repository.markNotificationAsRead(notification.id);
      _fetchData();
    }

    if (!mounted) return;

    final typeLower = notification.type.toLowerCase();

    if (typeLower.contains('patrol')) {
      Navigator.pushNamed(context, '/patrol'); 
    } else if (typeLower.contains('invitation') || typeLower.contains('schedule')) {
      Navigator.pushNamed(context, '/activity'); 
    } else {
      Navigator.pushNamed(context, '/patrol');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Biru yang Memenuhi Layar Atas
              DashboardHeader(
                userName: _isLoading ? '' : (_userName ?? ''),
                userDepartment: _isLoading ? '' : (_userDepartment ?? ''),
                initials: _isLoading ? '' : (_userInitials ?? ''),
                notificationCount: _unreadCount,
                onNotificationClosed: _fetchData,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: _buildBodyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dashboardData == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Grafik Trend
        TrendTemuanChart(
          trendPoints: _dashboardData!.trendPoints,
          currentFilter: _filter,
          onFilterChanged: _onFilterChanged,
        ),
        const SizedBox(height: 10), // Jarak diperketat pas rapat

        // 2. Ringkasan Status
        RingkasanStatusCards(
          stats: _dashboardData!.summaryStats,
          currentFilter: _filter,
        ),
        const SizedBox(height: 10), // Jarak sama presisi dengan atasnya (✓)

        // 3. Donut Chart
        StatusDonutChart(data: _dashboardData!.donutData),
        const SizedBox(height: 10),

        // 4. Daftar Notifikasi
        DashboardNotificationList(
          notifications: _notifications,
          onItemTap: _handleNotificationTap,
          onRefreshRequested: _fetchData,
        ),
        const SizedBox(height: 100), // Space aman untuk Floating Navbar
      ],
    );
  }
}