class TrendPoint {
  final String label; // 'Jan', 'Feb', ..., 'Des' ATAU 'W1', 'W2', ...
  final int openCount;
  final int inProgressCount;
  final int closedCount;

  TrendPoint({
    required this.label,
    required this.openCount,
    required this.inProgressCount,
    required this.closedCount,
  });
}