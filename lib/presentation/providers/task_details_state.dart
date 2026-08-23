import '../../domain/entities/task.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/user.dart';

enum TaskDetailsStatus { initial, loading, success, error }

class TaskDetailsState {
  final TaskDetailsStatus status;
  final AppTask? task;
  final List<Comment> comments;
  final String? errorMessage;
  final User? assignee;

  const TaskDetailsState({
    required this.status,
    this.task,
    this.comments = const [],
    this.errorMessage,
    this.assignee,
  });

  factory TaskDetailsState.initial() {
    return const TaskDetailsState(status: TaskDetailsStatus.initial);
  }

  TaskDetailsState copyWith({
    TaskDetailsStatus? status,
    AppTask? task,
    List<Comment>? comments,
    String? errorMessage,
    User? assignee,
  }) {
    return TaskDetailsState(
      status: status ?? this.status,
      task: task ?? this.task,
      comments: comments ?? this.comments,
      errorMessage: errorMessage ?? this.errorMessage,
      assignee: assignee ?? this.assignee,
    );
  }
}
