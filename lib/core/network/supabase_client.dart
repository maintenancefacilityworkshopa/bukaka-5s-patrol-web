import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Shortcut akses status user & session saat ini
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // Nama Storage Bucket untuk Upload Foto Patrol
  static const String patrolBucket = 'patrol_photos';
}