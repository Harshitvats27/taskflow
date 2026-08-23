import '../entities/requests.dart';
import '../entities/responses.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository _repository;

  UpdateTaskUseCase(this._repository);

  Future<TaskResponse> call(UpdateTaskRequest request) {
    return _repository.updateTask(request);
  }
}
