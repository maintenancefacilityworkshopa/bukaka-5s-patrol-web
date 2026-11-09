import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/dashboard_filter_model.dart';
import '../../data/models/trend_chart_model.dart';

enum PatrolStatusFilter { open, inProgress, closed }

class TrendTemuanChart extends StatefulWidget {
  final List<TrendPoint> trendPoints;
  final DashboardFilterModel currentFilter;
  final ValueChanged<DashboardFilterModel> onFilterChanged;

  const TrendTemuanChart({
    super.key,
    required this.trendPoints,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<TrendTemuanChart> createState() => _TrendTemuanChartState();
}

class _TrendTemuanChartState extends State<TrendTemuanChart> {
  // Status filter aktif (default awal: Open)
  PatrolStatusFilter _selectedStatus = PatrolStatusFilter.open;

  // Timer & kontrol auto slide animasi
  Timer? _autoSlideTimer;
  bool _isManualInteracted = false;

  // Rotasi animasi slide hanya 3 status (Open -> In Progress -> Closed)
  final List<PatrolStatusFilter> _autoSequence = [
    PatrolStatusFilter.open,
    PatrolStatusFilter.inProgress,
    PatrolStatusFilter.closed,
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isManualInteracted && mounted) {
        setState(() {
          int currentIndex = _autoSequence.indexOf(_selectedStatus);
          int nextIndex = (currentIndex + 1) % _autoSequence.length;
          _selectedStatus = _autoSequence[nextIndex];
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  String _getFilterLabel() {
    bool isMonthAll = widget.currentFilter.month == 'ALL';
    bool isYearAll = widget.currentFilter.year == 'ALL';

    if (isMonthAll && isYearAll) {
      return 'Periode Waktu';
    } else if (isMonthAll) {
      return widget.currentFilter.year;
    } else if (isYearAll) {
      return 'Bulan ${widget.currentFilter.month}';
    } else {
      return 'Bulan ${widget.currentFilter.month} / ${widget.currentFilter.year}';
    }
  }

  void _toggleStatusFilter(PatrolStatusFilter status) {
    setState(() {
      _isManualInteracted = true; // Hentikan auto-slide jika pengguna memilih manual
      _selectedStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayYear = widget.currentFilter.year == 'ALL'
        ? DateTime.now().year.toString()
        : widget.currentFilter.year;

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
          // Header Chart & Filter Interactive Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Temuan Patrol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Grafik pergerakan status patroli',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showWheelFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00569E).withValues(alpha: 0.08),
                          const Color(0xFF00569E).withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00569E).withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00569E).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Color(0xFF00569E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getFilterLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00569E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF00569E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Legend Interactive & Indikator Tahun
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInteractiveLegend('Open', const Color(0xFFEF4444), PatrolStatusFilter.open),
                      const SizedBox(width: 6),
                      _buildInteractiveLegend('In Progress', const Color(0xFFF59E0B), PatrolStatusFilter.inProgress),
                      const SizedBox(width: 6),
                      _buildInteractiveLegend('Closed', const Color(0xFF10B981), PatrolStatusFilter.closed),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tahun: $displayYear',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00569E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Body dengan Animasi Perpindahan Smooth
          SizedBox(
            height: 200,
            child: widget.trendPoints.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data trend untuk periode ini',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: KeyedSubtree(
                      key: ValueKey<PatrolStatusFilter>(_selectedStatus),
                      child: LineChart(_mainData()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveLegend(String label, Color color, PatrolStatusFilter status) {
    bool isSelected = _selectedStatus == status;
    double opacity = isSelected ? 1.0 : 0.35;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _toggleStatusFilter(status);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.6) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWheelFilterBottomSheet(BuildContext context) {
    final List<String> monthKeys = ['ALL', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    final List<String> monthNames = [
      'Semua', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final List<String> years = ['ALL', '2026', '2027', '2028', '2029'];

    int monthIdx = monthKeys.indexOf(widget.currentFilter.month).clamp(0, monthKeys.length - 1);
    int yearIdx = years.indexOf(widget.currentFilter.year).clamp(0, years.length - 1);

    final FixedExtentScrollController monthController = FixedExtentScrollController(initialItem: monthIdx);
    final FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: yearIdx);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Periode Patrol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: Center(child: Text('BULAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)))),
                        Expanded(child: Center(child: Text('TAHUN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00569E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.symmetric(
                                horizontal: BorderSide(color: const Color(0xFF00569E).withValues(alpha: 0.3), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: monthController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => monthIdx = index);
                                },
                                children: monthNames.map((name) => Center(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: monthNames.indexOf(name) == monthIdx ? FontWeight.bold : FontWeight.normal,
                                      color: monthNames.indexOf(name) == monthIdx ? const Color(0xFF00569E) : const Color(0xFF64748B),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: yearController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => yearIdx = index);
                                },
                                children: years.map((y) => Center(
                                  child: Text(
                                    y == 'ALL' ? 'Semua' : y,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: years.indexOf(y) == yearIdx ? FontWeight.bold : FontWeight.normal,
                                      color: years.indexOf(y) == yearIdx ? const Color(0xFF00569E) : const Color(0xFF64748B),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00569E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        widget.onFilterChanged(
                          DashboardFilterModel(
                            month: monthKeys[monthIdx],
                            year: years[yearIdx],
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  LineChartData _mainData() {
    double maxY = 5;
    for (var pt in widget.trendPoints) {
      if (_selectedStatus == PatrolStatusFilter.open && pt.openCount > maxY) {
        maxY = pt.openCount.toDouble();
      } else if (_selectedStatus == PatrolStatusFilter.inProgress && pt.inProgressCount > maxY) {
        maxY = pt.inProgressCount.toDouble();
      } else if (_selectedStatus == PatrolStatusFilter.closed && pt.closedCount > maxY) {
        maxY = pt.closedCount.toDouble();
      }
    }
    maxY = (maxY * 1.25).ceilToDouble();

    List<LineChartBarData> lines = [];

    if (_selectedStatus == PatrolStatusFilter.open) {
      lines.add(_createLineData(
        spots: widget.trendPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.openCount.toDouble())).toList(),
        color: const Color(0xFFEF4444),
      ));
    } else if (_selectedStatus == PatrolStatusFilter.inProgress) {
      lines.add(_createLineData(
        spots: widget.trendPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.inProgressCount.toDouble())).toList(),
        color: const Color(0xFFF59E0B),
      ));
    } else if (_selectedStatus == PatrolStatusFilter.closed) {
      lines.add(_createLineData(
        spots: widget.trendPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.closedCount.toDouble())).toList(),
        color: const Color(0xFF10B981),
      ));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: const Color(0xFFF1F5F9),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: maxY / 4 > 0 ? maxY / 4 : 1,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < widget.trendPoints.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    widget.trendPoints[index].label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.trendPoints.length - 1).toDouble() < 0 ? 0 : (widget.trendPoints.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: lines,
    );
  }

  LineChartBarData _createLineData({required List<FlSpot> spots, required Color color}) {
    return LineChartBarData(
      spots: spots,
      isCurved: false, // Menghasilkan garis lurus & tegas tanpa lengkungan
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3.0,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}