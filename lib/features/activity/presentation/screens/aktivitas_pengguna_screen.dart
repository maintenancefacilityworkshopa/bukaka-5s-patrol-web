import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../admin/patrol_schedule/presentation/screens/patrol_schedule_screen.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/models/activity_stat_model.dart';
import '../../data/models/completed_patrol_model.dart';
import '../../data/models/schedule_item_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../widgets/card_statistik_activity.dart';
import '../widgets/filter_dropdowns.dart';
import '../widgets/isi_schedule_filter.dart';
import '../widgets/isi_selesai_filter.dart';
import '../widgets/isi_semua_filter.dart';

class AktivitasPenggunaScreen extends StatefulWidget {
  const AktivitasPenggunaScreen({super.key});

  @override
  State<AktivitasPenggunaScreen> createState() => _AktivitasPenggunaScreenState();
}

class _AktivitasPenggunaScreenState extends State<AktivitasPenggunaScreen> {
  final ActivityRepository _repository = ActivityRepository();

  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isAdmin = false;

  String _selectedTimeFilter = 'Hari Ini';
  DateTime? _customSelectedDate;

  ActivityStatModel _stats = ActivityStatModel.empty();
  List<ActivityLogModel> _logsToday = [];
  List<ActivityLogModel> _logsYesterday = [];
  List<CompletedPatrolModel> _completedPatrols = [];
  List<ScheduleItemModel> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _pickCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customSelectedDate = picked;
        _selectedTimeFilter = DateFormat('dd/MM/yy').format(picked);
      });
      _loadActivityData();
    }
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);
    try {
      final payload = await _repository.fetchActivityData(_customSelectedDate);
      if (mounted) {
        setState(() {
          _isAdmin = payload.isAdmin;
          _stats = payload.stats;
          _logsToday = payload.logsToday;
          _logsYesterday = payload.logsYesterday;
          _completedPatrols = payload.completedPatrols;
          _schedules = payload.schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCreateSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatrolScheduleScreen(),
      ),
    ).then((_) => _loadActivityData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
                      'Pantau seluruh aktivitas Anda',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActivityData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            CardStatistikActivity(
                              totalPatrol: _stats.total,
                              selesai: _stats.selesai,
                              inProgress: _stats.inProgress,
                              open: _stats.open,
                              selectedTimeFilter: _selectedTimeFilter,
                              onSelectFilter: (value) {
                                if (value == 'Pilih Tanggal...') {
                                  _pickCustomDate();
                                } else if (value != null) {
                                  setState(() {
                                    _selectedTimeFilter = value;
                                    _customSelectedDate = null;
                                  });
                                  _loadActivityData();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            FilterDropdowns(
                              selectedTab: _selectedTab,
                              onTabChanged: (index) {
                                setState(() => _selectedTab = index);
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_selectedTab == 0)
                              IsiSemuaFilter(
                                logsToday: _logsToday,
                                logsYesterday: _logsYesterday,
                              )
                            else if (_selectedTab == 1)
                              IsiSelesaiFilter(
                                completedPatrols: _completedPatrols,
                              )
                            else
                              IsiScheduleFilter(
                                isAdmin: _isAdmin,
                                schedules: _schedules,
                                onAddSchedule: _navigateToCreateSchedule,
                              ),
                            const SizedBox(height: 24),
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