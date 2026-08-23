import '../../core/errors/exceptions.dart';
import '../entities/requests.dart';
import 'package:uuid/uuid.dart';
import '../repositories/auth_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/notification_repository.dart';
import '../entities/app_notification.dart';

class AssignUserToTaskUseCase {
  final TaskRepository _taskRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;
  final NotificationRepository _notificationRepository;

  AssignUserToTaskUseCase(
    this._taskRepository,
    this._userRepository,
    this._authRepository,
    this._notificationRepository,
  );

  Future<void> execute(String taskId, String userId) async {
    final session = await _authRepository.getCurrentSession();
    if (session == null) {
      throw ValidationException('No active session.');
    }

    final members = await _userRepository.getOrgMembers(session.orgId);
    final isMember = members.any((m) => m.id == userId);
    if (!isMember) {
      throw ValidationException('User does not belong to this organization.');
    }

    await _taskRepository.updateTask(
      UpdateTaskRequest(
        id: taskId,
        assigneeId: userId,
      ),
    );

    // Generate a notification for the assigned user
    // Don't send notification to ourselves if we assign a task to ourselves
    if (session.userId != userId) {
      await _notificationRepository.addNotification(
        AppNotification(
          id: const Uuid().v4(),
          userId: userId,
          type: 'task_assigned',
          taskId: taskId,
          message: 'You were assigned to a new task',
          read: false,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}