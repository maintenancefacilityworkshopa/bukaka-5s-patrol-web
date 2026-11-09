import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream data realtime dari tabel profiles
  Stream<List<UserModel>> getUsersStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserModel.fromJson(json)).toList());
  }

  // Fetch daftar departemen untuk pilihan dropdown
  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final response = await _supabase.from('departments').select('id, name');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  // Simpan atau Update Profile Pengguna
  Future<void> saveUser({required UserModel user, String? userId}) async {
    final payload = user.toJson();
    if (userId == null || userId.isEmpty) {
      await _supabase.from('profiles').insert(payload);
    } else {
      await _supabase.from('profiles').update(payload).eq('id', userId);
    }
  }

  // Hapus Pengguna dari database
  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}