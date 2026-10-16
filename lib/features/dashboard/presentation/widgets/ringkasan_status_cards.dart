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
    // Menentukan konteks periode (Mingguan vs Bulanan)
    final bool isSpecificMonth = currentFilter.month != 'ALL';
    final String periodText = isSpecificMonth ? 'Week' : 'Bulan';
    final String periodLabel = isSpecificMonth ? 'Minggu' : 'Bulan';
    final String totalTitle = isSpecificMonth ? 'Total Bulan Ini' : 'Total Tahun Ini';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            // 1. Rata-rata per periode
            _buildStatCard(
              title: 'Rata-rata per $periodText',
              value: stats.averagePerPeriod.toStringAsFixed(1).replaceAll('.', ','),
              unit: 'Temuan',
              icon: Icons.grid_view_rounded,
              accentColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
            ),
            
            // 2. Periode Tertinggi
            _buildStatCard(
              title: '$periodLabel Tertinggi',
              value: stats.highestCount.toString(),
              unit: 'Temuan (${stats.highestPeriod})',
              icon: Icons.trending_up_rounded,
              accentColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
            ),

            // 3. Periode Terendah
            _buildStatCard(
              title: '$periodLabel Terendah',
              value: stats.lowestCount.toString(),
              unit: 'Temuan (${stats.lowestPeriod})',
              icon: Icons.trending_down_rounded,
              accentColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
            ),

            // 4. Total Temuan
            _buildStatCard(
              title: totalTitle,
              value: stats.totalCount.toString(),
              unit: 'Temuan',
              icon: Icons.pie_chart_outline_rounded,
              accentColor: const Color(0xFF0284C7),
              bgColor: const Color(0xFFEFF6FF),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 6),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
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