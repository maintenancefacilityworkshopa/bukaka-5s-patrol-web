import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patrol_model.dart';

class PatrolRemoteDatasource {
  final SupabaseClient _supabase;

  PatrolRemoteDatasource(this._supabase);

  /// 1. REALTIME STREAM PATROLS
  Stream<List<PatrolModel>> streamPatrols() {
    return _supabase
        .from('patrols')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (dataList) => dataList
              .map((map) => PatrolModel.fromMap(map))
              .toList(),
        );
  }

  /// 2. FETCH PROFILES MAP
  Future<Map<String, String>> fetchProfilesMap(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final profilesRes = await _supabase
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', userIds);

    return {
      for (final profile in profilesRes)
        profile['id'].toString():
            profile['full_name']?.toString() ?? 'Pengguna',
    };
  }

  /// 3. CREATE PATROL
  Future<PatrolModel> createPatrol(
    Map<String, dynamic> patrolData,
  ) async {
    try {
      final response = await _supabase
          .from('patrols')
          .insert(patrolData)
          .select()
          .single();

      debugPrint(
        'Patrol berhasil dibuat di Supabase: ${response['kode_patrol']}',
      );

      return PatrolModel.fromMap(response);
    } catch (e) {
      debugPrint('Create Patrol Error: $e');
      rethrow;
    }
  }

  /// 4. UPDATE PATROL
  Future<PatrolModel> updatePatrol(
    dynamic id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final response = await _supabase
          .from('patrols')
          .update(updatedData)
          .eq('id', id)
          .select()
          .single();

      debugPrint(
        'Patrol berhasil diperbarui di Supabase: ${response['kode_patrol']}',
      );

      return PatrolModel.fromMap(response);
    } catch (e) {
      debugPrint('Update Patrol Error: $e');
      rethrow;
    }
  }

  /// 5. DELETE PATROL
  Future<void> deletePatrol(
    dynamic id, {
    String? kodePatrol,
  }) async {
    try {
      await _supabase
          .from('patrols')
          .delete()
          .eq('id', id);

      debugPrint(
        'Patrol berhasil dihapus dari Supabase: $kodePatrol / $id',
      );
    } catch (e) {
      debugPrint('Delete Patrol Error: $e');
      rethrow;
    }
  }

  /// 6. GET CURRENT USER ROLE
  Future<String?> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    return data['role']?.toString();
  }

  /// 7. GET CURRENT USER ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}