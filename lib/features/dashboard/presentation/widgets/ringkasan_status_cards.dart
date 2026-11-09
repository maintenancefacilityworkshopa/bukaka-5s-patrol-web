import 'package:flutter/material.dart';
import '../../data/models/summary_stat_model.dart';
import '../../data/models/dashboard_filter_model.dart';

class RingkasanStatusCards extends StatelessWidget {
  final SummaryStatModel stats;
  final DashboardFilterModel currentFilter;

  const RingkasanStatusCards({
    super.key,
    required this.stats,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSpecificMonth = currentFilter.month != 'ALL';
    final String periodText = isSpecificMonth ? 'Week' : 'Bulan';
    final String periodLabel = isSpecificMonth ? 'Minggu' : 'Bulan';
    final String totalTitle = isSpecificMonth ? 'Total Bulan Ini' : 'Total Tahun Ini';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ringkasan Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8), // Jarak rapat sama seperti centang (✓)
        
        // Baris 1: Rata-rata & Tertinggi
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Rata-rata per $periodText',
                value: stats.averagePerPeriod.toStringAsFixed(1).replaceAll('.', ','),
                unit: 'Temuan',
                icon: Icons.grid_view_rounded,
                accentColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: '$periodLabel Tertinggi',
                value: stats.highestCount.toString(),
                unit: 'Temuan (${stats.highestPeriod})',
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Jarak rapat antar kartu

        // Baris 2: Terendah & Total
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '$periodLabel Terendah',
                value: stats.lowestCount.toString(),
                unit: 'Temuan (${stats.lowestPeriod})',
                icon: Icons.trending_down_rounded,
                accentColor: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: totalTitle,
                value: stats.totalCount.toString(),
                unit: 'Temuan',
                icon: Icons.pie_chart_outline_rounded,
                accentColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}