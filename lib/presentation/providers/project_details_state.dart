import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/task.dart';

enum ProjectDetailsStatus { initial, loading, success, error }

class ProjectDetailsState extends Equatable {
  final ProjectDetailsStatus status;
  final Project? project;
  final List<AppTask> tasks;
  final String? errorMessage;

  const ProjectDetailsState({
    required this.status,
    this.project,
    required this.tasks,
    this.errorMessage,
  });

  factory ProjectDetailsState.initial() => const ProjectDetailsState(
        status: ProjectDetailsStatus.initial,
        tasks: [],
      );

  ProjectDetailsState copyWith({
    ProjectDetailsStatus? status,
    Project? project,
    List<AppTask>? tasks,
    String? errorMessage,
  }) {
    return ProjectDetailsState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, project, tasks, errorMessage];
}
