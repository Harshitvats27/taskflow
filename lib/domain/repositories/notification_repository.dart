import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotificationsForUser(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> addNotification(AppNotification notification);
}