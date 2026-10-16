class SummaryStatModel {
  final double averagePerPeriod;
  final int highestCount;
  final String highestPeriod;
  final int lowestCount;
  final String lowestPeriod;
  final int totalCount;
  final bool isMonthlyFilter;

  SummaryStatModel({
    required this.averagePerPeriod,
    required this.highestCount,
    required this.highestPeriod,
    required this.lowestCount,
    required this.lowestPeriod,
    required this.totalCount,
    required this.isMonthlyFilter,
  });

  // Factory pendukung jika menggunakan default data / fallback
  factory SummaryStatModel.empty() {
    return SummaryStatModel(
      averagePerPeriod: 0.0,
      highestCount: 0,
      highestPeriod: '-',
      lowestCount: 0,
      lowestPeriod: '-',
      totalCount: 0,
      isMonthlyFilter: false,
    );
  }
}