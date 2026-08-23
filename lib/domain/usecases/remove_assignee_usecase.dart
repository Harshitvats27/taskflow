import '../entities/requests.dart';
import '../repositories/task_repository.dart';

class RemoveAssigneeUseCase {
  final TaskRepository _taskRepository;

  RemoveAssigneeUseCase(this._taskRepository);

  Future<void> execute(String taskId) async {
    await _taskRepository.updateTask(
      UpdateTaskRequest(
        id: taskId,
        clearAssignee: true,
      ),
    );
  }
}
