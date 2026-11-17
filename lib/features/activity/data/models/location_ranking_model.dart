class LocationRankingModel {
  final int rank;
  final String locationName;
  final String locationDescription;
  final int totalPatrol;
  final int openCount;
  final int inProgressCount;
  final int closedCount;

  const LocationRankingModel({
    required this.rank,
    required this.locationName,
    required this.locationDescription,
    required this.totalPatrol,
    required this.openCount,
    required this.inProgressCount,
    required this.closedCount,
  });
}