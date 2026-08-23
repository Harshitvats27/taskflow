// Response wrappers live in the domain layer.
// They wrap entities with any additional metadata a real API might return
// (e.g. pagination cursor, server-assigned IDs). No JSON here.

import 'project.dart';
import 'task.dart';

class ProjectResponse {
  final Project project;

  const ProjectResponse({required this.project});
}

class TaskResponse {
  final AppTask task;

  const TaskResponse({required this.task});
}

/// Generic paginated wrapper — not used now but mirrors what a real HTTP layer
/// would return so swapping to a live backend requires no domain changes.
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final String? nextCursor;

  const PaginatedResponse({
    required this.items,
    required this.total,
    this.nextCursor,
  });
}
