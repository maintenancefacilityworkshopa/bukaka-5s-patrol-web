import 'package:flutter/material.dart';

class CardStatistikActivity extends StatelessWidget {
  final int totalPatrol;
  final int selesai;
  final int inProgress;
  final int open;
  final String selectedTimeFilter;
  final ValueChanged<String?>? onSelectFilter;

  const CardStatistikActivity({
    super.key,
    this.totalPatrol = 12,
    this.selesai = 8,
    this.inProgress = 4,
    this.open = 1,
    this.selectedTimeFilter = 'Hari Ini',
    this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    final double progressPercentage =
        totalPatrol > 0 ? (selesai / totalPatrol).clamp(0.0, 1.0) : 0.0;
    final int percentInt = (progressPercentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Blue Theme
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card dengan Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ringkasan Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Statistik patrol Anda saat ini',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Dropdown Filter Tanggal (Hari Ini, dd/mm/yy)
              PopupMenuButton<String>(
                onSelected: onSelectFilter,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        selectedTimeFilter,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Hari Ini',
                    child: Text('Hari Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'Pilih Tanggal...',
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text('Pilih Tanggal (dd/mm/yy)', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid Layout 2x2
          Row(
            children: [
              Expanded(
                child: _buildGridBox(
                  title: 'Total Patrol',
                  value: '$totalPatrol',
                  subtext: '▲ +2 dari bulan lalu',
                  subtextColor: const Color(0xFF16A34A),
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridBox(
                  title: 'Selesai',
                  value: '$selesai',
                  subtext: '$percentInt% dari total',
                  subtextColor: const Color(0xFF64748B),
                  icon: Icons.check_circle_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGridBox(
                  title: 'In Progress',
                  value: '$inProgress',
                  subtext: 'Sedang dikerjakan',
                  subtextColor: const Color(0xFF64748B),
                  icon: Icons.access_time_filled_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridBox(
                  title: 'Open',
                  value: '$open',
                  subtext: 'Perlu tindakan',
                  subtextColor: const Color(0xFFDC2626),
                  icon: Icons.error_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bar Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Keseluruhan',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.center_focus_strong_rounded, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '$selesai dari $totalPatrol patrol telah selesai',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridBox({
    required String title,
    required String value,
    required String subtext,
    required Color subtextColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: subtextColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}