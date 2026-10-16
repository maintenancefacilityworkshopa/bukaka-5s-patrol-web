import 'package:flutter/material.dart';
import '../../models/patrol_schedule_model.dart';

class PatrolScheduleTable extends StatelessWidget {
  final List<PatrolScheduleModel> schedules;
  final ValueChanged<PatrolScheduleModel> onDetail;
  final ValueChanged<PatrolScheduleModel> onEdit;
  final ValueChanged<String> onDelete;

  const PatrolScheduleTable({
    super.key,
    required this.schedules,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('JUDUL SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
            DataColumn(label: Text('AREA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
            DataColumn(label: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
            DataColumn(label: Text('INSPEKTUR / PJ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
            DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)))),
          ],
          rows: schedules.map((item) {
            final isAktif = item.status == 'Aktif';
            return DataRow(
              cells: [
                DataCell(Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                DataCell(Text(item.area, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                DataCell(Text(
                  item.date.isNotEmpty ? item.date : 'Minggu Ke-${item.weekNumber} (${item.month} ${item.year})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                )),
                DataCell(Text(item.inspectorName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAktif ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAktif ? const Color(0xFF166534) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF2563EB)),
                        onPressed: () => onDetail(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD97706)),
                        onPressed: () => onEdit(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                        onPressed: () {
                          if (item.id != null) {
                            onDelete(item.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}