import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/requests.dart';
import 'auth_notifier.dart';
import 'task_list_state.dart';

final taskListProvider = NotifierProvider<TaskListNotifier, TaskListState>(
  () => TaskListNotifier(),
);

class TaskListNotifier extends Notifier<TaskListState> {
  @override
  TaskListState build() {
    return TaskListState.initial();
  }

  Future<void> fetchTasks({TaskFilter? initialFilter}) async {
    final filter = initialFilter ?? state.filter;
    state = state.copyWith(status: TaskListStatus.loading, filter: filter);

    try {
      final useCase = ref.read(getTasksUseCaseProvider);
      
      // If no orgId is explicitly provided and we are requesting global tasks (no projectId),
      // we must limit tasks to the user's current organization.
      String? orgId = filter.orgId;
      if (orgId == null && filter.projectId == null) {
        final session = ref.read(authNotifierProvider).session;
        if (session != null) {
          orgId = session.orgId;
        }
      }

      final activeFilter = TaskFilter(
        orgId: orgId,
        projectId: filter.projectId,
        status: filter.status,
        priority: filter.priority,
        assigneeId: filter.assigneeId,
        dueBefore: filter.dueBefore,
        dueAfter: filter.dueAfter,
      );

      final tasks = await useCase.call(filter: activeFilter);
      
      state = state.copyWith(
        status: tasks.isEmpty ? TaskListStatus.empty : TaskListStatus.success,
        tasks: tasks,
        filter: activeFilter, // Keep track of the resolved active filter
      );
    } catch (e) {
      state = state.copyWith(
        status: TaskListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateFilter(TaskFilter newFilter) async {
    await fetchTasks(initialFilter: newFilter);
  }

  Future<void> quickUpdateStatus(String taskId, String newStatus) async {
    try {
      await ref.read(updateTaskUseCaseProvider).call(UpdateTaskRequest(id: taskId, status: newStatus));
      await fetchTasks();
    } catch (e) {
      // Could show a snackbar via an event stream, but for now we ignore/re-throw
      rethrow;
    }
  }

  Future<void> quickUpdatePriority(String taskId, String newPriority) async {
    try {
      await ref.read(updateTaskUseCaseProvider).call(UpdateTaskRequest(id: taskId, priority: newPriority));
      await fetchTasks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await ref.read(deleteTaskUseCaseProvider).call(taskId);
      await fetchTasks();
    } catch (e) {
      rethrow;
    }
  }
}
