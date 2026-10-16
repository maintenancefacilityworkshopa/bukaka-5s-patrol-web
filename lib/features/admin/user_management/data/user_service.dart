import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Realtime Stream untuk tabel profiles
  Stream<List<UserModel>> getUsersStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserModel.fromJson(json)).toList());
  }

  // Fetch daftar departemen untuk dropdown
  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final response = await _supabase.from('departments').select('id, name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Simpan atau Update Profile User
  Future<void> saveUser({required UserModel user, String? userId}) async {
    final payload = user.toJson();
    if (userId == null) {
      await _supabase.from('profiles').insert(payload);
    } else {
      await _supabase.from('profiles').update(payload).eq('id', userId);
    }
  }

  // Hapus User
  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}