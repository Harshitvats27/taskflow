import '../../core/errors/exceptions.dart';
import '../entities/session.dart';
import '../repositories/project_repository.dart';

class DeleteProjectUseCase {
  final ProjectRepository _repository;
  DeleteProjectUseCase(this._repository);

  Future<void> execute(Session session, String projectId) async {
    if (session.role != 'org_admin') {
      throw UnauthorizedException(
          'Only organization administrators can delete projects.');
    }
    await _repository.deleteProject(projectId);
  }
}
