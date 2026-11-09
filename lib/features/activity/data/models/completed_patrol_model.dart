class CompletedPatrolModel {
  final String locationName;
  final String finishedAt;
  final dynamic rawPatrolData;

  CompletedPatrolModel({
    required this.locationName,
    required this.finishedAt,
    this.rawPatrolData,
  });

  factory CompletedPatrolModel.fromMap(Map<String, dynamic> map) {
    return CompletedPatrolModel(
      locationName: map['lokasi'] ?? map['locationName'] ?? 'Maintenance Area',
      finishedAt: map['finished_at'] ?? map['finishedAt'] ?? '-',
      rawPatrolData: map,
    );
  }
}