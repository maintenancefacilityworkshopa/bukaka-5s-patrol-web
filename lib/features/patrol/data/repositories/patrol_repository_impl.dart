import 'dart:async';
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
  Future<Map<String, String>> getProfilesMap(List<String> userIds) async {
    final profiles = await _remoteDatasource.fetchProfilesMap(userIds);
    return profiles.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<PatrolModel> createPatrol(Map<String, dynamic> patrolData) {
    return _remoteDatasource.createPatrol(patrolData);
  }

  @override
  Future<PatrolModel> updatePatrol(dynamic id, Map<String, dynamic> updatedData) {
    return _remoteDatasource.updatePatrol(id, updatedData);
  }

  @override
  Future<void> deletePatrol(dynamic id, {String? kodePatrol}) {
    return _remoteDatasource.deletePatrol(id, kodePatrol: kodePatrol);
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