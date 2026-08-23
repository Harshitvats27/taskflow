import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  Future<void> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}
