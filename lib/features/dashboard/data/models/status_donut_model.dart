class StatusDonutData {
  final int open;
  final int inProgress;
  final int closed;

  StatusDonutData({
    required this.open,
    required this.inProgress,
    required this.closed,
  });

  int get total => open + inProgress + closed;

  double get openPercentage => total == 0 ? 0 : (open / total) * 100;
  double get inProgressPercentage => total == 0 ? 0 : (inProgress / total) * 100;
  double get closedPercentage => total == 0 ? 0 : (closed / total) * 100;

  factory StatusDonutData.empty() {
    return StatusDonutData(open: 0, inProgress: 0, closed: 0);
  }
}