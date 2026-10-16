class DashboardFilterModel {
  final String month; // 'ALL', '1', '2', ..., '12'
  final String year;  // 'ALL', '2024', '2025', '2026', '2027', '2028', '2029'

  const DashboardFilterModel({
    this.month = 'ALL',
    this.year = 'ALL',
  });

  DashboardFilterModel copyWith({
    String? month,
    String? year,
  }) {
    return DashboardFilterModel(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}