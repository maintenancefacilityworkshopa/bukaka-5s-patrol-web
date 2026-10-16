import '../../data/models/patrol_model.dart';

abstract class PatrolRepository {
  /// Stream data real-time seluruh patroli dari database
  Stream<List<PatrolModel>> getPatrolsStream();

  /// Mengambil pemetaan ID pengguna ke nama lengkap profil
  Future<Map<String, String>> getProfilesMap(List<String> userIds);

  /// Menghapus data patroli berdasarkan ID
  Future<void> deletePatrol(dynamic id);

  /// Mengecek role pengguna saat ini (misal: ADMIN atau USER)
  Future<String?> getCurrentUserRole();

  /// Mendapatkan ID pengguna yang sedang login
  String? getCurrentUserId();
}