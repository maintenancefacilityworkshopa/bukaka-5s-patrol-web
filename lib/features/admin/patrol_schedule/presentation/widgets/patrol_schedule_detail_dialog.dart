import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatrolScheduleDetailDialog extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const PatrolScheduleDetailDialog({super.key, required this.schedule});

  @override
  State<PatrolScheduleDetailDialog> createState() =>
      _PatrolScheduleDetailDialogState();
}

class _PatrolScheduleDetailDialogState
    extends State<PatrolScheduleDetailDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch data detail jadwal lengkap dengan Join ke locations & profiles
  Future<List<Map<String, dynamic>>> _fetchScheduleDetails() async {
    final scheduleId = widget.schedule['id'];
    if (scheduleId == null) return [];

    final response = await _supabase
        .from('schedule_details')
        .select('''
          id,
          week_number,
          shift_order,
          locations (id, name),
          profiles (id, full_name)
        ''')
        .eq('schedule_id', scheduleId)
        .order('week_number', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  /// Mengelompokkan data berdasarkan Lokasi & Siklus Minggu (M1 & M3 / M2 & M4)
  List<Map<String, dynamic>> _processGroupedDetails(
      List<Map<String, dynamic>> details) {
    final Map<String, Map<String, dynamic>> groupedMap = {};

    for (var item in details) {
      final locName =
          item['locations']?['name']?.toString().trim() ?? 'Lokasi Tidak Diketahui';
      final userName =
          item['profiles']?['full_name']?.toString().trim() ?? 'Petugas Tidak Diketahui';
      final week = item['week_number'] ?? 1;

      // Kelompokkan minggu 1 & 3 sebagai M1 & M3, serta 2 & 4 sebagai M2 & M4
      final isOddWeek = (week == 1 || week == 3);
      final weekLabel = isOddWeek ? 'M1 & M3' : 'M2 & M4';
      final key = '$locName|$weekLabel';

      if (!groupedMap.containsKey(key)) {
        groupedMap[key] = {
          'location_name': locName,
          'week_label': weekLabel,
          'is_odd': isOddWeek,
          'officers': <String>[],
        };
      }

      // Tambahkan nama petugas secara unik (menghindari duplikasi)
      final List<String> officers = groupedMap[key]!['officers'];
      if (!officers.contains(userName)) {
        officers.add(userName);
      }
    }

    return groupedMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.schedule['title'] ?? 'Detail Jadwal';
    final isActive = widget.schedule['is_active'] ?? true;
    final startDateStr = _formatDateString(widget.schedule['start_date']);
    final endDateStr = _formatDateString(widget.schedule['end_date']);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchScheduleDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final details = snapshot.data ?? [];

            // Hitung total lokasi unik & petugas unik
            final uniqueLocations = details
                .map((d) => d['locations']?['name'])
                .where((name) => name != null)
                .toSet();
            final uniqueUsers = details
                .map((d) => d['profiles']?['full_name'])
                .where((name) => name != null)
                .toSet();

            final groupedList = _processGroupedDetails(details);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF00569E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 24),

                // Ringkasan Card Status, Total Lokasi, Total Petugas
                Row(
                  children: [
                    _buildSummaryCard(
                      'Status',
                      isActive ? 'Aktif' : 'Non-Aktif',
                      isActive ? Colors.green.shade700 : Colors.grey.shade700,
                      isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      'Total Lokasi',
                      '${uniqueLocations.length} Lokasi',
                      Colors.black87,
                      Colors.grey.shade100,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      'Total Petugas',
                      '${uniqueUsers.length} Petugas',
                      Colors.black87,
                      Colors.grey.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Periode Tanggal
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Periode: $startDateStr s/d $endDateStr',
                    style: const TextStyle(
                      color: Color(0xFF00569E),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Detail Penugasan Import:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Content List Penugasan Terkelompok
                SizedBox(
                  height: 320,
                  child: groupedList.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada detail penugasan ditemukan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: groupedList.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final group = groupedList[index];
                            final locName = group['location_name'] as String;
                            final weekLabel = group['week_label'] as String;
                            final isOdd = group['is_odd'] as bool;
                            final officers = group['officers'] as List<String>;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isOdd
                                        ? Colors.blue.shade100
                                        : Colors.orange.shade100,
                                    child: Text(
                                      isOdd ? 'M1,3' : 'M2,4',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isOdd
                                            ? const Color(0xFF2563EB)
                                            : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$locName ($weekLabel)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Petugas: ${officers.join(', ')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}