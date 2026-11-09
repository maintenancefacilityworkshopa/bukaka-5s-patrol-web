// lib/features/activity/presentation/widgets/isi_semua_filter.dart
import 'package:flutter/material.dart';
import '../../data/models/activity_log_model.dart';

class IsiSemuaFilter extends StatelessWidget {
  final List<ActivityLogModel> logsToday;
  final List<ActivityLogModel> logsYesterday;
  final Function(dynamic patrolData)? onItemTap;

  const IsiSemuaFilter({
    super.key,
    required this.logsToday,
    required this.logsYesterday,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (logsToday.isEmpty && logsYesterday.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  size: 36,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Riwayat Aktivitas Tidakk Ada',
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
        if (logsToday.isNotEmpty) ...[
          const Text(
            'DAFTAR AKTIVITAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...logsToday.map((item) => _buildLogCard(context, item)),
        ],
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, ActivityLogModel item) {
    String datePart = '';
    String timePart = item.time;

    if (item.time.contains(' ')) {
      final parts = item.time.split(' ');
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
                color: item.iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.code} • ${item.location}',
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
  }
}