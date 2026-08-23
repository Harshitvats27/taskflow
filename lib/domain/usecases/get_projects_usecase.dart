import '../entities/project.dart';
import '../repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository _repository;
  GetProjectsUseCase(this._repository);

  Future<List<Project>> execute(String orgId) =>
      _repository.getProjectsByOrgId(orgId);
}