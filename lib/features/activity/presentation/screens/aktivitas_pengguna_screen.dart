// lib/features/activity/presentation/screens/aktivitas_pengguna_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/models/activity_stat_model.dart';
import '../../data/models/completed_patrol_model.dart';
import '../../data/models/location_ranking_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../widgets/card_statistik_activity.dart';
import '../widgets/filter_dropdowns.dart';
import '../widgets/isi_in_progress_filter.dart';
import '../widgets/isi_open_admin_filter.dart';
import '../widgets/isi_peringkat_location_filter.dart';
import '../widgets/isi_selesai_filter.dart';
import '../widgets/isi_semua_filter.dart';
import '../widgets/month_year_picker_dialog.dart';
import '../../../patrol/presentation/screens/detail_patrol_screen.dart';

class AktivitasPenggunaScreen extends StatefulWidget {
  const AktivitasPenggunaScreen({super.key});

  @override
  State<AktivitasPenggunaScreen> createState() =>
      _AktivitasPenggunaScreenState();
}

class _AktivitasPenggunaScreenState extends State<AktivitasPenggunaScreen> {
  final ActivityRepository _repository = ActivityRepository();

  bool _isAdmin = false;
  int _selectedTab = 0;
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedTimeFilterText = 'Bulan Ini';

  List<String> _availableLocations = [];
  String _selectedLocation = 'Semua Lokasi';

  ActivityStatModel _stats = ActivityStatModel.empty();
  List<ActivityLogModel> _logsToday = [];
  List<ActivityLogModel> _logsYesterday = [];
  List<CompletedPatrolModel> _completedPatrols = [];
  List<LocationRankingModel> _locationRankings = [];

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  String _formatFilterButtonLabel() {
    String timePart;
    if (_selectedMonth == 0 && _selectedYear == 0) {
      timePart = 'Semua Waktu';
    } else if (_selectedMonth == 0) {
      timePart = 'Tahun $_selectedYear';
    } else if (_selectedYear == 0) {
      timePart = 'Bulan $_selectedMonth';
    } else if (_selectedMonth == DateTime.now().month &&
        _selectedYear == DateTime.now().year) {
      timePart = 'Bulan Ini';
    } else {
      timePart = '$_selectedMonth/$_selectedYear';
    }

    if (_selectedLocation == 'Semua Lokasi') {
      return timePart;
    }
    return '$timePart • $_selectedLocation';
  }

  Future<void> _showMonthYearPicker() async {
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MonthYearPickerDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
        locations: _availableLocations,
        initialLocation: _selectedLocation,
      ),
    );

    if (res != null) {
      setState(() {
        _selectedMonth = res['month'] ?? 0;
        _selectedYear = res['year'] ?? 0;
        _selectedLocation = res['location'] ?? 'Semua Lokasi';
        _selectedTimeFilterText = _formatFilterButtonLabel();
      });
      _loadActivityData();
    }
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);
    try {
      final payload = await _repository.fetchActivityData(
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
        selectedLocation: _selectedLocation,
      );
      if (mounted) {
        setState(() {
          _isAdmin = payload.isAdmin;
          _availableLocations = payload.availableLocations;
          _stats = payload.stats;
          _logsToday = payload.logsToday;
          _logsYesterday = payload.logsYesterday;
          _completedPatrols = payload.completedPatrols;
          _locationRankings = payload.locationRankings;
          _selectedTimeFilterText = _formatFilterButtonLabel();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDetail(dynamic patrolData) {
    if (patrolData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPatrolScreen(patrolData: patrolData),
      ),
    ).then((_) => _loadActivityData());
  }

  @override
  Widget build(BuildContext context) {
    // Filter log untuk Tab In Progress (Non-Admin)
    final List<ActivityLogModel> inProgressLogs = _logsToday.where((item) {
      final st = item.status.toUpperCase();
      return st == 'IN PROGRESS' ||
          st == 'IN_PROGRESS' ||
          st == 'PROSES' ||
          st == 'OPEN' ||
          st == 'PENDING';
    }).toList();

    // Filter log khusus status OPEN untuk Tab Open (Admin)
    final List<ActivityLogModel> openOnlyLogs = _logsToday.where((item) {
      final st = item.status.toUpperCase();
      return st == 'OPEN' || st == 'PENDING';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pantau seluruh aktivitas patrol',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActivityData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // 1. Card Ringkasan Statistik + Tombol Filter Terpadu (Periode & Locations)
                            CardStatistikActivity(
                              totalPatrol: _stats.total,
                              selesai: _stats.selesai,
                              inProgress: _stats.inProgress,
                              open: _stats.open,
                              selectedTimeFilter: _selectedTimeFilterText,
                              onTapFilter: _showMonthYearPicker,
                            ),
                            const SizedBox(height: 14),

                            // 2. Tab Role-Based (Admin vs Non-Admin)
                            FilterDropdowns(
                              isAdmin: _isAdmin,
                              selectedTab: _selectedTab,
                              onTabChanged: (index) {
                                setState(() => _selectedTab = index);
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. Konten Berdasarkan POV Role & Tab Aktif
                            if (_isAdmin) ...[
                              if (_selectedTab == 0)
                                IsiSemuaFilter(
                                  logsToday: _logsToday,
                                  logsYesterday: _logsYesterday,
                                  onItemTap: (data) => _navigateToDetail(data),
                                )
                              else if (_selectedTab == 1)
                                IsiOpenAdminFilter(
                                  openLogs: openOnlyLogs,
                                  onItemTap: (data) => _navigateToDetail(data),
                                )
                              else
                                IsiPeringkatLocationFilter(
                                  rankings: _locationRankings,
                                  onLocationTap: (locName) {
                                    setState(() {
                                      _selectedLocation = locName;
                                      _selectedTab = 0;
                                    });
                                    _loadActivityData();
                                  },
                                ),
                            ] else ...[
                              if (_selectedTab == 0)
                                IsiSemuaFilter(
                                  logsToday: _logsToday,
                                  logsYesterday: _logsYesterday,
                                  onItemTap: (data) => _navigateToDetail(data),
                                )
                              else if (_selectedTab == 1)
                                IsiInProgressFilter(
                                  inProgressLogs: inProgressLogs,
                                  onItemTap: (data) => _navigateToDetail(data),
                                )
                              else
                                IsiSelesaiFilter(
                                  completedPatrols: _completedPatrols,
                                  onItemTap: (data) => _navigateToDetail(data),
                                ),
                            ],
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}