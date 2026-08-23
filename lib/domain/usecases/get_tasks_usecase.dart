import '../entities/task.dart';
import '../entities/requests.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  Future<List<AppTask>> call({TaskFilter? filter}) {
    return _repository.getTasks(filter: filter);
  }
}
