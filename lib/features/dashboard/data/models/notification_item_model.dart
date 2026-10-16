class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'patrol', 'schedule', 'invitation', dll.
  final bool isRead;
  final String? referenceId;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.referenceId,
  });

  factory NotificationItemModel.fromMap(Map<String, dynamic> map) {
    return NotificationItemModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'Notifikasi',
      message: map['message'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      type: map['type'] ?? 'patrol',
      isRead: map['is_read'] ?? false,
      referenceId: map['reference_id']?.toString(),
    );
  }
}