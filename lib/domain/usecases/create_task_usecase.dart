import '../entities/requests.dart';
import '../entities/responses.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository _repository;
  CreateTaskUseCase(this._repository);

  Future<TaskResponse> execute(CreateTaskRequest request) =>
      _repository.createTask(request);
}