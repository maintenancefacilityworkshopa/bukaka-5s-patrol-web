import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patrol_model.dart';

class PatrolService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream data real-time untuk daftar seluruh patroli
  Stream<List<PatrolModel>> streamPatrols() {
    return _supabase
        .from('patrols')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((dataList) =>
            dataList.map((map) => PatrolModel.fromMap(map)).toList());
  }

  /// Membuat data patroli baru
  Future<void> createPatrol(Map<String, dynamic> patrolData) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum terautentikasi.');

    final dataToInsert = {
      ...patrolData,
      'created_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('patrols').insert(dataToInsert);
  }

  /// Mengubah (Edit) data patroli
  Future<void> updatePatrol({
    required String patrolId,
    required Map<String, dynamic> updatedData,
  }) async {
    await _supabase
        .from('patrols')
        .update(updatedData)
        .eq('id', patrolId);
  }

  /// Menghapus data patroli
  Future<void> deletePatrol(String patrolId) async {
    await _supabase
        .from('patrols')
        .delete()
        .eq('id', patrolId);
  }

  /// Mengambil alih penanganan patroli (OPEN -> IN_PROGRESS)
  Future<void> startHandlingPatrol(String patrolId, String userRole) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Pengguna belum terautentikasi.');

    await _supabase.from('patrols').update({
      'status': 'IN_PROGRESS',
      'handled_by': user.id,
      'handled_by_role': userRole,
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', patrolId);
  }

  /// Menyelesaikan penanganan patroli (IN_PROGRESS -> CLOSED)
  Future<void> completePatrol({
    required String patrolId,
    required String fotoAfterUrl,
    required String deskripsiTindakan,
  }) async {
    await _supabase.from('patrols').update({
      'foto_sesudah_url': fotoAfterUrl,
      'deskripsi_tindakan': deskripsiTindakan,
      'status': 'CLOSED',
      'finished_at': DateTime.now().toIso8601String(),
    }).eq('id', patrolId);
  }
}