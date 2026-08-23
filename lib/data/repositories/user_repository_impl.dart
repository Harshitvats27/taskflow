import '../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/mock_json_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;

  UserRepositoryImpl(this._dataSource, this._simulator);

  @override
  Future<User> getUserById(String id) {
    return _simulator.simulate(() async {
      _simulator.checkForceNotFound(id, label: 'User');
      final users = await _dataSource.getUsers();
      final match = users.where((u) => u.id == id).toList();
      if (match.isEmpty) throw NotFoundException('User "$id" not found');
      return match.first;
    });
  }

  @override
  Future<List<User>> getOrgMembers(String orgId) {
    return _simulator.simulate(() async {
      final orgMembers = await _dataSource.getOrgMembers();
      final memberIds = orgMembers
          .where((m) => m.orgId == orgId)
          .map((m) => m.userId)
          .toSet();

      final users = await _dataSource.getUsers();
      return users.where((u) => memberIds.contains(u.id)).toList();
    });
  }
}
