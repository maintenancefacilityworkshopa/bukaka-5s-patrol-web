import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Login menggunakan Email & Password yang sudah didaftarkan oleh Admin di Supabase Auth
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Ambil Profil Lengkap dari tabel `public.profiles` milik pengguna yang sedang aktif
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('id, nik, full_name, role, department_id')
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  /// Logout dari Supabase
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}