import 'summary_stat_model.dart';
import 'status_donut_model.dart';
import 'trend_chart_model.dart';

class DashboardDataModel {
  final List<TrendPoint> trendPoints;
  final SummaryStatModel summaryStats;
  final StatusDonutData donutData;

  DashboardDataModel({
    required this.trendPoints,
    required this.summaryStats,
    required this.donutData,
  });
}