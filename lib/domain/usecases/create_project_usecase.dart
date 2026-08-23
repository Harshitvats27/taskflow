import '../entities/requests.dart';
import '../entities/responses.dart';
import '../repositories/project_repository.dart';

class CreateProjectUseCase {
  final ProjectRepository _repository;
  CreateProjectUseCase(this._repository);

  Future<ProjectResponse> execute(CreateProjectRequest request) =>
      _repository.createProject(request);
}
