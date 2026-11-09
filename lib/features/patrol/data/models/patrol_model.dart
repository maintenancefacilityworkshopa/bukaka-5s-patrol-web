class PatrolModel {
  final String id;
  final String? kodePatrol;
  final String? judul;
  final String createdBy;
  final String? nameMaker;
  final String? role;
  final String? locationId;
  final String lokasi;
  final String item5s;
  final String? deskripsi;
  final String? deskripsiTindakan;
  final String? priorityLevel;
  final String? fotoBefore;
  final String? fotoAfter;
  final String status;
  final String? handledBy;
  final String? handledByRole;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  PatrolModel({
    required this.id,
    this.kodePatrol,
    this.judul,
    required this.createdBy,
    this.nameMaker,
    this.role,
    this.locationId,
    required this.lokasi,
    required this.item5s,
    this.deskripsi,
    this.deskripsiTindakan,
    this.priorityLevel,
    this.fotoBefore,
    this.fotoAfter,
    required this.status,
    this.handledBy,
    this.handledByRole,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory PatrolModel.fromMap(Map<String, dynamic> map) {
    return PatrolModel(
      id: map['id']?.toString() ?? '',
      kodePatrol: map['kode_patrol']?.toString() ?? map['kode']?.toString(),
      judul: map['judul']?.toString() ?? map['title']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      nameMaker: map['name_maker']?.toString() ??
          map['nama_pembuat']?.toString() ??
          map['pelapor_nama']?.toString(),
      role: map['role']?.toString(),
      locationId: map['location_id']?.toString(),
      lokasi: map['lokasi']?.toString() ?? map['location']?.toString() ?? '',
      item5s: map['item_5s']?.toString() ?? '',
      deskripsi: map['deskripsi']?.toString() ?? map['description']?.toString(),
      deskripsiTindakan: map['deskripsi_tindakan']?.toString(),
      priorityLevel: map['priority_level']?.toString() ??
          map['kelas_tingkatan']?.toString() ??
          'LOW',
      fotoBefore: map['foto_sebelum_url']?.toString(),
      fotoAfter: map['foto_sesudah_url']?.toString(),
      status: (map['status']?.toString() ?? 'OPEN').toUpperCase(),
      handledBy: map['handled_by']?.toString(),
      handledByRole: map['handled_by_role']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : (map['tanggal'] != null
              ? DateTime.tryParse(map['tanggal'].toString())?.toLocal() ??
                  DateTime.now()
              : DateTime.now()),
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'].toString())?.toLocal()
          : null,
      finishedAt: map['finished_at'] != null
          ? DateTime.tryParse(map['finished_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (kodePatrol != null) 'kode_patrol': kodePatrol,
      if (judul != null) 'judul': judul,
      'created_by': createdBy,
      if (nameMaker != null) 'nama_pembuat': nameMaker,
      if (role != null) 'role': role,
      if (locationId != null) 'location_id': locationId,
      'lokasi': lokasi,
      'item_5s': item5s,
      'deskripsi': deskripsi,
      if (deskripsiTindakan != null) 'deskripsi_tindakan': deskripsiTindakan,
      'kelas_tingkatan': priorityLevel ?? 'LOW',
      'foto_sebelum_url': fotoBefore,
      'foto_sesudah_url': fotoAfter,
      'status': status,
      if (handledBy != null) 'handled_by': handledBy,
      if (handledByRole != null) 'handled_by_role': handledByRole,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }
}