import 'package:flutter/material.dart';
import '../../data/patrol_schedule_service.dart';
import '../../models/patrol_schedule_model.dart';
import '../widgets/patrol_schedule_table.dart';
import '../widgets/patrol_schedule_mobile.dart';
import '../widgets/patrol_schedule_empty.dart';
import '../widgets/patrol_schedule_filter.dart';
import '../widgets/patrol_schedule_dialog.dart';
import '../widgets/patrol_schedule_detail_dialog.dart';
import '../widgets/import_excel_dialog.dart';

class PatrolScheduleScreen extends StatefulWidget {
  const PatrolScheduleScreen({super.key});

  @override
  State<PatrolScheduleScreen> createState() => _PatrolScheduleScreenState();
}

class _PatrolScheduleScreenState extends State<PatrolScheduleScreen> {
  final PatrolScheduleService _service = PatrolScheduleService();

  String _period = 'Bulan';
  String _selectedMonth = 'September';
  String _selectedYear = '2026';
  int _selectedWeek = 1;
  String _searchQuery = '';

  static const primaryBlue = Color(0xFF2563EB);

  final List<String> _monthsList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  int _getMonthNumber(String monthName) {
    int index = _monthsList.indexOf(monthName);
    return index != -1 ? index + 1 : DateTime.now().month;
  }

  void _showFormDialog([PatrolScheduleModel? schedule]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PatrolScheduleDialog(
        schedule: schedule,
        onSave: (newSchedule) async {
          final monthInt = _getMonthNumber(_selectedMonth);
          final yearInt = int.tryParse(_selectedYear) ?? 2026;
          
          final startDate = DateTime(yearInt, monthInt, 1);
          final endDate = DateTime(yearInt, monthInt + 1, 0);

          await _service.saveSchedule(
            title: '${newSchedule.title} $_selectedMonth $_selectedYear',
            description: newSchedule.area,
            startDate: startDate,
            endDate: endDate,
          );

          if (dialogContext.mounted) {
            Navigator.pop(dialogContext, true);
          }
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showImportExcelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportExcelDialog(),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showDetailDialog(PatrolScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (context) => PatrolScheduleDetailDialog(
        schedule: schedule.toMap(),
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    try {
      await _service.deleteSchedule(id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus jadwal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthInt = _getMonthNumber(_selectedMonth);
    final yearInt = int.tryParse(_selectedYear);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar Schedule Patrol',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _service.streamSchedulesByFilter(
            month: monthInt.toString(),
            year: yearInt?.toString(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryBlue));
            }

            final rawData = snapshot.data ?? [];
            
            // Konversi dari Map Supabase ke PatrolScheduleModel
            final rawSchedules = rawData.map((map) {
              final model = PatrolScheduleModel.fromMap(map);
              
              // Hitung jumlah lokasi & petugas unik dari detail jika ada
              final details = map['schedule_details'] as List<dynamic>? ?? [];
              final uniqueLocs = details.map((d) => d['location_id']).where((id) => id != null).toSet();
              final uniqueUsers = details.map((d) => d['user_id']).where((id) => id != null).toSet();

              return model.copyWith(
                totalLocations: uniqueLocs.isNotEmpty ? uniqueLocs.length : model.totalLocations,
                totalInspectors: uniqueUsers.isNotEmpty ? uniqueUsers.length : model.totalInspectors,
              );
            }).toList();

            final filteredSchedules = rawSchedules.where((item) {
              final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  item.area.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesWeek = _period == 'Minggu' ? item.weekNumber == _selectedWeek : true;
              return matchesSearch && matchesWeek;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PatrolScheduleFilter(
                    period: _period,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    selectedWeek: _selectedWeek,
                    onPeriodChanged: (val) => setState(() => _period = val),
                    onMonthChanged: (val) => setState(() => _selectedMonth = val!),
                    onYearChanged: (val) => setState(() => _selectedYear = val!),
                    onWeekChanged: (val) => setState(() => _selectedWeek = val),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                  _buildMetricsFromData(rawData),
                  const SizedBox(height: 24),
                  
                  _buildHeaderAndSearch(),
                  
                  const SizedBox(height: 14),
                  if (filteredSchedules.isEmpty)
                    PatrolScheduleEmpty(onCreateSchedule: () => _showFormDialog())
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 768) {
                          return PatrolScheduleMobile(
                            schedules: filteredSchedules,
                            onDetail: _showDetailDialog,
                            onEdit: _showFormDialog,
                            onDelete: _handleDelete,
                          );
                        }
                        return PatrolScheduleTable(
                          schedules: filteredSchedules,
                          onDetail: _showDetailDialog,
                          onEdit: _showFormDialog,
                          onDelete: _handleDelete,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Kalkulasi kartu metrik secara dinamis langsung dari data mentah Supabase
  Widget _buildMetricsFromData(List<Map<String, dynamic>> rawData) {
    final Set<String> globalLocations = {};
    final Set<String> globalUsers = {};
    int activeCount = 0;

    for (var item in rawData) {
      if (item['is_active'] == true) {
        activeCount++;
      }
      final details = item['schedule_details'] as List<dynamic>? ?? [];
      for (var d in details) {
        if (d['location_id'] != null) globalLocations.add(d['location_id'].toString());
        if (d['user_id'] != null) globalUsers.add(d['user_id'].toString());
      }
    }

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      childAspectRatio: 2.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metricTile('Total Schedule', '${rawData.length}', Icons.calendar_month, const Color(0xFF2563EB)),
        _metricTile('Total Lokasi', '${globalLocations.length}', Icons.location_on, const Color(0xFF16A34A)),
        _metricTile('Total Petugas', '${globalUsers.length}', Icons.groups, const Color(0xFF9333EA)),
        _metricTile('Jadwal Aktif', '$activeCount', Icons.event_available, const Color(0xFFEA580C)),
      ],
    );
  }

  Widget _metricTile(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _showImportExcelDialog,
          icon: const Icon(Icons.upload_file_outlined, size: 16, color: Color(0xFF334155)),
          label: const Text(
            'Import Excel',
            style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _showFormDialog(),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text(
            'Buat Schedule',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAndSearch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            const Text(
              'Daftar Schedule yang Tersimpan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (isMobile) const SizedBox(height: 10),
            SizedBox(
              width: isMobile ? double.infinity : 320,
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari schedule...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}