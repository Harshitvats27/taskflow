import '../../domain/entities/task.dart';
import '../../domain/entities/requests.dart';

enum TaskListStatus { initial, loading, success, empty, error }

class TaskListState {
  final TaskListStatus status;
  final List<AppTask> tasks;
  final TaskFilter filter;
  final String? errorMessage;

  const TaskListState({
    required this.status,
    this.tasks = const [],
    this.filter = const TaskFilter(),
    this.errorMessage,
  });

  factory TaskListState.initial({TaskFilter initialFilter = const TaskFilter()}) {
    return TaskListState(status: TaskListStatus.initial, filter: initialFilter);
  }

  TaskListState copyWith({
    TaskListStatus? status,
    List<AppTask>? tasks,
    TaskFilter? filter,
    String? errorMessage,
  }) {
    return TaskListState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
