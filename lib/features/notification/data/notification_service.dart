import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream Data Notifikasi Real-time
  Stream<List<NotificationModel>> streamNotifications({required bool isAdmin}) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => NotificationModel.fromMap(item))
              .where((item) {
                // Jika admin: tampilkan semua atau yang ditujukan ke admin
                if (isAdmin) return true;
                // Jika user biasa: tampilkan notifikasi publik/sistem atau yang spesifik user tersebut
                return item.userId == null || item.userId == currentUserId;
              })
              .toList();
        });
  }

  // Tandai Notifikasi Telah Dibaca
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Tandai Semua Notifikasi Dibaca
  Future<void> markAllAsRead() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUserId);
    }
  }
}