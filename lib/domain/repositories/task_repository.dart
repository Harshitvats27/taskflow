import '../entities/task.dart';
import '../entities/requests.dart';
import '../entities/responses.dart';

abstract class TaskRepository {
  /// Returns tasks optionally filtered by [filter].
  Future<List<AppTask>> getTasks({
    TaskFilter? filter,
  });

  /// Returns a single task wrapped in [TaskResponse].
  /// Throws [NotFoundException] if unknown.
  /// Special trigger: id == "task_force_404" always throws [NotFoundException].
  Future<TaskResponse> getTaskById(String id);

  /// Creates a new task from [request].
  /// Throws [ValidationException] if [request.title] or [request.projectId] are empty.
  Future<TaskResponse> createTask(CreateTaskRequest request);

  /// Updates an existing task. Only non-null fields in [request] are applied.
  /// Throws [ValidationException] if the resulting title would be empty.
  Future<TaskResponse> updateTask(UpdateTaskRequest request);

  /// Deletes the task with [id].
  Future<void> deleteTask(String id);
}