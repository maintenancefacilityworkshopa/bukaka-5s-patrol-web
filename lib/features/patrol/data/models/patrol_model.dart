class PatrolModel {
  final String id;
  final String? kodePatrol;
  final String createdBy;
  final String? handledBy;
  final String? handledByRole;
  final String lokasi;
  final String item5s;
  final String? deskripsi;
  final String? deskripsiTindakan;
  final String? fotoBefore;
  final String? fotoAfter;
  final String status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  PatrolModel({
    required this.id,
    this.kodePatrol,
    required this.createdBy,
    this.handledBy,
    this.handledByRole,
    required this.lokasi,
    required this.item5s,
    this.deskripsi,
    this.deskripsiTindakan,
    this.fotoBefore,
    this.fotoAfter,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory PatrolModel.fromMap(Map<String, dynamic> map) {
    return PatrolModel(
      id: map['id'] ?? '',
      kodePatrol: map['kode_patrol'] ?? map['kode'],
      createdBy: map['created_by'] ?? '',
      handledBy: map['handled_by'],
      handledByRole: map['handled_by_role'],
      lokasi: map['lokasi'] ?? '',
      item5s: map['item_5s'] ?? '',
      deskripsi: map['deskripsi'],
      deskripsiTindakan: map['deskripsi_tindakan'],
      fotoBefore: map['foto_sebelum_url'] ?? map['foto_before'],
      fotoAfter: map['foto_sesudah_url'] ?? map['foto_after'],
      status: map['status'] ?? 'OPEN',
      createdAt: DateTime.parse(
          map['created_at'] ?? map['tanggal'] ?? DateTime.now().toIso8601String()),
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at']) : null,
      finishedAt: map['finished_at'] != null ? DateTime.parse(map['finished_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (kodePatrol != null) 'kode_patrol': kodePatrol,
      'created_by': createdBy,
      'handled_by': handledBy,
      'handled_by_role': handledByRole,
      'lokasi': lokasi,
      'item_5s': item5s,
      'deskripsi': deskripsi,
      'deskripsi_tindakan': deskripsiTindakan,
      'foto_sebelum_url': fotoBefore,
      'foto_sesudah_url': fotoAfter,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }
}