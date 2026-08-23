import '../entities/user.dart';

abstract class UserRepository {
  Future<User> getUserById(String id);
  Future<List<User>> getOrgMembers(String orgId);
}