import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/requests.dart';
import '../../domain/entities/user.dart';
import 'task_details_state.dart';

final taskDetailsProvider = NotifierProvider<TaskDetailsNotifier, TaskDetailsState>(
  () => TaskDetailsNotifier(),
);

class TaskDetailsNotifier extends Notifier<TaskDetailsState> {
  @override
  TaskDetailsState build() {
    return TaskDetailsState.initial();
  }

  Future<void> loadTask(String taskId) async {
    state = state.copyWith(status: TaskDetailsStatus.loading);
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final commentRepo = ref.read(commentRepositoryProvider);

      final taskRes = await taskRepo.getTaskById(taskId);
      final comments = await commentRepo.getCommentsByTaskId(taskId);
      
      User? assignee;
      if (taskRes.task.assigneeId != null) {
        try {
          assignee = await ref.read(userRepositoryProvider).getUserById(taskRes.task.assigneeId!);
        } catch (_) {
          assignee = null;
        }
      }

      state = state.copyWith(
        status: TaskDetailsStatus.success,
        task: taskRes.task,
        comments: comments,
        assignee: assignee,
      );
    } catch (e) {
      state = state.copyWith(
        status: TaskDetailsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateStatus(String status) async {
    if (state.task == null) return;
    try {
      final useCase = ref.read(updateTaskUseCaseProvider);
      await useCase.call(UpdateTaskRequest(id: state.task!.id, status: status));
      await loadTask(state.task!.id); // reload completely
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePriority(String priority) async {
    if (state.task == null) return;
    try {
      final useCase = ref.read(updateTaskUseCaseProvider);
      await useCase.call(UpdateTaskRequest(id: state.task!.id, priority: priority));
      await loadTask(state.task!.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignUser(String? userId) async {
    if (state.task == null) return;
    try {
      if (userId == null) {
        final useCase = ref.read(removeAssigneeUseCaseProvider);
        await useCase.execute(state.task!.id);
      } else {
        final useCase = ref.read(assignUserToTaskUseCaseProvider);
        await useCase.execute(state.task!.id, userId);
      }
      await loadTask(state.task!.id);
    } catch (e) {
      rethrow;
    }
  }
}
