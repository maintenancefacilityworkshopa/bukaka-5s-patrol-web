import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream Notifikasi Real-time dari Supabase (Filter < 2 Bulan & Hak Akses User)
  Stream<List<NotificationModel>> streamNotifications({required bool isAdmin}) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((dataList) {
          return dataList
              .map((item) => NotificationModel.fromMap(item))
              .where((item) {
                // Filter 1: Hapus tampilan visual notifikasi yang berumur lebih dari 2 bulan
                if (item.createdAt.isBefore(twoMonthsAgo)) {
                  return false;
                }

                // Filter 2: Saring Hak Akses Berdasarkan User / Admin
                if (isAdmin) return true;
                return item.userId == null || item.userId == currentUserId;
              })
              .toList();
        });
  }

  /// Tandai Notifikasi Spesifik sebagai Dibaca
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  /// Tandai Semua Notifikasi Milik Pengguna Saat Ini sebagai Dibaca
  Future<void> markAllAsRead() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      try {
        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', currentUserId);
      } catch (_) {}
    }
  }

  /// Kirim Notifikasi Baru ke Database
  Future<void> sendNotification({
    String? userId,
    required String title,
    required String message,
    required String type,
    String? referenceId,
  }) async {
    await _supabase.from('notifications').insert({
      if (userId != null) 'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      if (referenceId != null) 'reference_id': referenceId,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}