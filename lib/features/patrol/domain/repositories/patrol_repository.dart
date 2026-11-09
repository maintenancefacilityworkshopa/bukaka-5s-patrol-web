import 'dart:async';
import '../../data/models/patrol_model.dart';

abstract class PatrolRepository {
  /// Stream data real-time seluruh patroli dari database Supabase
  Stream<List<PatrolModel>> getPatrolsStream();

  /// Mengambil pemetaan ID pengguna ke nama lengkap profil
  Future<Map<String, String>> getProfilesMap(List<String> userIds);

  /// Membuat data patroli baru
  Future<PatrolModel> createPatrol(Map<String, dynamic> patrolData);

  /// Mengubah data patroli berdasarkan ID
  Future<PatrolModel> updatePatrol(dynamic id, Map<String, dynamic> updatedData);

  /// Menghapus data patroli berdasarkan ID
  Future<void> deletePatrol(dynamic id, {String? kodePatrol});

  /// Mengecek role pengguna saat ini (ADMIN, PIC_AREA, STAFF_AHLI)
  Future<String?> getCurrentUserRole();

  /// Mendapatkan ID pengguna yang sedang login
  String? getCurrentUserId();
}