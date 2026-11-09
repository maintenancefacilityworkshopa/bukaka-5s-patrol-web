// lib/features/activity/presentation/widgets/isi_selesai_filter.dart
import 'package:flutter/material.dart';
import '../../data/models/completed_patrol_model.dart';

class IsiSelesaiFilter extends StatelessWidget {
  final List<CompletedPatrolModel> completedPatrols;
  final Function(dynamic patrolData)? onItemTap;

  const IsiSelesaiFilter({
    super.key,
    required this.completedPatrols,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (completedPatrols.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 36,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Riwayat Aktivitas Selesai Tidak Ada',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TEMUAN SELESAI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...completedPatrols.map((item) {
          final String code = item.rawPatrolData != null && item.rawPatrolData['kode_patrol'] != null
              ? item.rawPatrolData['kode_patrol'].toString().replaceAll('SK-', 'NP-')
              : 'NP-2026-0001';

          String datePart = '';
          String timePart = item.finishedAt;

          if (item.finishedAt.contains(' ')) {
            final parts = item.finishedAt.split(' ');
            datePart = parts[0];
            timePart = parts[1];
          }

          return InkWell(
            onTap: () {
              if (onItemTap != null && item.rawPatrolData != null) {
                onItemTap!(item.rawPatrolData);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patroli Selesai',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$code • ${item.locationName}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (datePart.isNotEmpty)
                        Text(
                          datePart,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        timePart,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}