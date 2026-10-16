import '../../domain/repositories/patrol_repository.dart';
import '../datasources/patrol_remote_datasource.dart';
import '../models/patrol_model.dart';

class PatrolRepositoryImpl implements PatrolRepository {
  final PatrolRemoteDatasource _remoteDatasource;

  PatrolRepositoryImpl(this._remoteDatasource);

  @override
  Stream<List<PatrolModel>> getPatrolsStream() {
    return _remoteDatasource.streamPatrols();
  }

  @override
  Future<Map<String, String>> getProfilesMap(List<String> userIds) {
    return _remoteDatasource.fetchProfilesMap(userIds);
  }

  @override
  Future<void> deletePatrol(dynamic id) {
    return _remoteDatasource.deletePatrol(id);
  }

  @override
  Future<String?> getCurrentUserRole() {
    return _remoteDatasource.getCurrentUserRole();
  }

  @override
  String? getCurrentUserId() {
    return _remoteDatasource.getCurrentUserId();
  }
}