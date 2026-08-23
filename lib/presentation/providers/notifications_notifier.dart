import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'auth_notifier.dart';
import 'notifications_state.dart';

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends Notifier<NotificationsState> {
  late GetNotificationsUseCase _getNotifications;
  late MarkNotificationReadUseCase _markNotificationRead;

  @override
  NotificationsState build() {
    _getNotifications = ref.read(getNotificationsUseCaseProvider);
    _markNotificationRead = ref.read(markNotificationReadUseCaseProvider);
    return NotificationsInitial();
  }

  Future<void> fetchNotifications() async {
    state = NotificationsLoading();
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated || authState.session == null) {
        state = const NotificationsError('Not authenticated');
        return;
      }
      final notifications = await _getNotifications(authState.session!.userId);
      
      // Sort by created at descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (notifications.isEmpty) {
        state = NotificationsEmpty();
      } else {
        state = NotificationsSuccess(notifications);
      }
    } catch (e) {
      state = NotificationsError(e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _markNotificationRead(notificationId);
      // Optimistically update the list in memory if it's currently success
      if (state is NotificationsSuccess) {
        // Actually, re-fetching is cleaner and less error prone.
        await fetchNotifications();
      }
    } catch (e) {
      // Ignored in UI
    }
  }
}
