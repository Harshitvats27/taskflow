import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';

enum ProjectListStatus { initial, loading, success, empty, error }

class ProjectListState extends Equatable {
  final ProjectListStatus status;
  final List<Project> projects;
  final String? errorMessage;

  const ProjectListState({
    required this.status,
    required this.projects,
    this.errorMessage,
  });

  factory ProjectListState.initial() => const ProjectListState(
        status: ProjectListStatus.initial,
        projects: [],
      );

  ProjectListState copyWith({
    ProjectListStatus? status,
    List<Project>? projects,
    String? errorMessage,
  }) {
    return ProjectListState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, projects, errorMessage];
}
