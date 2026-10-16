class PatrolScheduleModel {
  final String? id;
  final String title;
  final String area;
  final String status;
  final int totalLocations;
  final int totalInspectors;
  final String inspectorName;
  final int weekNumber;
  final String month;
  final String year;
  final String date;
  final String shift;

  PatrolScheduleModel({
    this.id,
    required this.title,
    required this.area,
    required this.status,
    required this.totalLocations,
    required this.totalInspectors,
    required this.inspectorName,
    required this.weekNumber,
    required this.month,
    required this.year,
    this.date = '',
    this.shift = 'Shift 1',
  });

  PatrolScheduleModel copyWith({
    String? id,
    String? title,
    String? area,
    String? status,
    int? totalLocations,
    int? totalInspectors,
    String? inspectorName,
    int? weekNumber,
    String? month,
    String? year,
    String? date,
    String? shift,
  }) {
    return PatrolScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      status: status ?? this.status,
      totalLocations: totalLocations ?? this.totalLocations,
      totalInspectors: totalInspectors ?? this.totalInspectors,
      inspectorName: inspectorName ?? this.inspectorName,
      weekNumber: weekNumber ?? this.weekNumber,
      month: month ?? this.month,
      year: year ?? this.year,
      date: date ?? this.date,
      shift: shift ?? this.shift,
    );
  }

  factory PatrolScheduleModel.fromMap(Map<String, dynamic> map) {
    return PatrolScheduleModel(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      area: map['area'] ?? '',
      status: map['status'] ?? 'Aktif',
      totalLocations: map['total_locations'] ?? 0,
      totalInspectors: map['total_inspectors'] ?? 0,
      inspectorName: map['inspector_name'] ?? '',
      weekNumber: map['week_number'] ?? 1,
      month: map['month'] ?? 'Agustus',
      year: map['year'] ?? '2026',
      date: map['date'] ?? '',
      shift: map['shift'] ?? 'Shift 1',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'area': area,
      'status': status,
      'total_locations': totalLocations,
      'total_inspectors': totalInspectors,
      'inspector_name': inspectorName,
      'week_number': weekNumber,
      'month': month,
      'year': year,
      'date': date,
      'shift': shift,
    };
  }
}