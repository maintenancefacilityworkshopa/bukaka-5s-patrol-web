import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patrol_model.dart';

class PatrolRemoteDatasource {
  final SupabaseClient _supabase;

  PatrolRemoteDatasource(this._supabase);

  Stream<List<PatrolModel>> streamPatrols() {
    return _supabase
        .from('patrols')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((dataList) =>
            dataList.map((map) => PatrolModel.fromMap(map)).toList());
  }

  Future<Map<String, String>> fetchProfilesMap(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final profilesRes = await _supabase
        .from('profiles')
        .select('id, full_name')
        .filter('id', 'in', userIds);

    return {
      for (var p in profilesRes)
        p['id'].toString(): p['full_name']?.toString() ?? 'Pengguna'
    };
  }

  Future<void> deletePatrol(dynamic id) async {
    await _supabase.from('patrols').delete().eq('id', id);
  }

  Future<String?> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return data?['role']?.toString();
  }

  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}