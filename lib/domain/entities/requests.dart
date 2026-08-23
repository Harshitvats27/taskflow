// Request models live in the domain layer so use cases can construct them
// without depending on data/. They carry only primitive or entity types —
// NO JSON / serialisation logic here.

/// Passed to [ProjectRepository.createProject].
class CreateProjectRequest {
  final String orgId;
  final String name;
  final String description;

  const CreateProjectRequest({
    required this.orgId,
    required this.name,
    required this.description,
  });
}

/// Passed to [ProjectRepository.updateProject].
class UpdateProjectRequest {
  final String id;
  final String? name;
  final String? description;
  final String? status;

  const UpdateProjectRequest({
    required this.id,
    this.name,
    this.description,
    this.status,
  });
}

/// Passed to [TaskRepository.createTask].
class CreateTaskRequest {
  final String projectId;
  final String title;
  final String description;
  final String status;   // "todo" | "in_progress" | "review" | "done"
  final String priority; // "low" | "medium" | "high" | "urgent"
  final String? assigneeId;
  final DateTime dueDate;

  const CreateTaskRequest({
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.dueDate,
  });
}

/// Passed to [TaskRepository.updateTask].
class UpdateTaskRequest {
  final String id;
  final String? title;
  final String? description;
  final String? status;
  final String? priority;
  /// Use [UpdateTaskRequest.unassign] sentinel to explicitly clear the assignee.
  final String? assigneeId;
  final bool clearAssignee;
  final DateTime? dueDate;

  const UpdateTaskRequest({
    required this.id,
    this.title,
    this.description,
    this.status,
    this.priority,
    this.assigneeId,
    this.clearAssignee = false,
    this.dueDate,
  });
}

/// Filter parameters for [TaskRepository.getTasks].
class TaskFilter {
  final String? orgId;
  final String? projectId;
  final String? status;
  final String? priority;
  final String? assigneeId;
  final DateTime? dueBefore;
  final DateTime? dueAfter;

  const TaskFilter({
    this.orgId,
    this.projectId,
    this.status,
    this.priority,
    this.assigneeId,
    this.dueBefore,
    this.dueAfter,
  });

  bool get isEmpty =>
      orgId == null &&
      projectId == null &&
      status == null &&
      priority == null &&
      assigneeId == null &&
      dueBefore == null &&
      dueAfter == null;
}
