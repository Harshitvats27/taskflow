import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<List<AppNotification>> call(String userId) {
    return _repository.getNotificationsForUser(userId);
  }
}
