import 'package:flutter/material.dart';
import '../../models/patrol_schedule_model.dart';

class PatrolScheduleMobile extends StatelessWidget {
  final List<PatrolScheduleModel> schedules;
  final ValueChanged<PatrolScheduleModel> onDetail;
  final ValueChanged<PatrolScheduleModel> onEdit;
  final ValueChanged<String> onDelete;

  const PatrolScheduleMobile({
    super.key,
    required this.schedules,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = schedules[index];
        final isAktif = item.status == 'Aktif';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAktif ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAktif ? const Color(0xFF166534) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Area: ${item.area}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Tanggal: ${item.date.isNotEmpty ? item.date : "Minggu Ke-${item.weekNumber} (${item.month} ${item.year})"}' ,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                'PJ: ${item.inspectorName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => onDetail(item),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Detail', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
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
            ],
          ),
        );
      },
    );
  }
}