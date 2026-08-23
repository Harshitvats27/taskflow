import '../entities/requests.dart';
import '../entities/responses.dart';
import '../repositories/project_repository.dart';

class UpdateProjectUseCase {
  final ProjectRepository _repository;
  UpdateProjectUseCase(this._repository);

  Future<ProjectResponse> execute(UpdateProjectRequest request) =>
      _repository.updateProject(request);
}
