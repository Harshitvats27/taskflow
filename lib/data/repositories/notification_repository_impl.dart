import '../../core/errors/exceptions.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/mock_json_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;

  NotificationRepositoryImpl(this._dataSource, this._simulator);

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId) {
    return _simulator.simulate(() async {
      final all = await _dataSource.getNotifications();
      return all.where((n) => n.userId == userId).toList();
    });
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _simulator.simulate(() async {
      final all = await _dataSource.getNotifications();
      final match = all.where((n) => n.id == notificationId).toList();
      if (match.isEmpty) {
        throw NotFoundException('Notification "$notificationId" not found');
      }

      final old = match.first;
      final updated = NotificationModel(
        id: old.id,
        userId: old.userId,
        type: old.type,
        taskId: old.taskId,
        message: old.message,
        read: true,
        createdAt: old.createdAt,
      );

      await _dataSource.updateNotification(updated);
    });
  }

  @override
  Future<void> addNotification(AppNotification notification) {
    return _simulator.simulate(() async {
      final model = NotificationModel(
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        taskId: notification.taskId,
        message: notification.message,
        read: notification.read,
        createdAt: notification.createdAt,
      );
      await _dataSource.addNotification(model);
    });
  }
}
