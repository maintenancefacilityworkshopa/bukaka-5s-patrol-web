class ActivityStatModel {
  final int total;
  final int selesai;
  final int inProgress;
  final int open;

  const ActivityStatModel({
    required this.total,
    required this.selesai,
    required this.inProgress,
    required this.open,
  });

  factory ActivityStatModel.empty() {
    return const ActivityStatModel(
      total: 0,
      selesai: 0,
      inProgress: 0,
      open: 0,
    );
  }
}