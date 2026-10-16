import 'package:flutter/material.dart';

class PatrolScheduleEmpty extends StatelessWidget {
  final VoidCallback onCreateSchedule;

  const PatrolScheduleEmpty({
    super.key,
    required this.onCreateSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Schedule Patrol',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tidak ada jadwal patroli yang ditemukan untuk periode ini.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onCreateSchedule,
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Buat Schedule Baru', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}