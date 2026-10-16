import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/status_donut_model.dart';

class StatusDonutChart extends StatefulWidget {
  final StatusDonutData data;

  const StatusDonutChart({super.key, required this.data});

  @override
  State<StatusDonutChart> createState() => _StatusDonutChartState();
}

class _StatusDonutChartState extends State<StatusDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final int total = widget.data.total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temuan Berdasarkan Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Chart Donut dengan Center Label
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          sections: _showingSections(total),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '$total',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Detail Legenda
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendRow(
                      color: const Color(0xFFEF4444),
                      title: 'Open',
                      count: widget.data.open,
                      total: total,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendRow(
                      color: const Color(0xFFF59E0B),
                      title: 'In Progress',
                      count: widget.data.inProgress,
                      total: total,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendRow(
                      color: const Color(0xFF10B981),
                      title: 'Closed',
                      count: widget.data.closed,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(int total) {
    if (total == 0) {
      return [
        PieChartSectionData(
          color: const Color(0xFFE2E8F0),
          value: 1,
          title: '',
          radius: 16,
        )
      ];
    }

    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 22.0 : 16.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFFEF4444),
            value: widget.data.open.toDouble(),
            title: '',
            radius: radius,
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xFFF59E0B),
            value: widget.data.inProgress.toDouble(),
            title: '',
            radius: radius,
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFF10B981),
            value: widget.data.closed.toDouble(),
            title: '',
            radius: radius,
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegendRow({
    required Color color,
    required String title,
    required int count,
    required int total,
  }) {
    final double percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Text(
          '$count ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}