import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/notifications_notifier.dart';
import '../providers/notifications_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/loading_indicator.dart';

String _formatDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationsProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading || state is NotificationsInitial) {
      return const Center(child: LoadingIndicator());
    } else if (state is NotificationsError) {
      return ErrorStateView(
        message: state.message,
        onRetry: () =>
            ref.read(notificationsProvider.notifier).fetchNotifications(),
      );
    } else if (state is NotificationsEmpty) {
      return const EmptyStateView(
        title: 'No notifications',
        message: 'You have no notifications at the moment.',
        icon: Icons.notifications_none,
      );
    } else if (state is NotificationsSuccess) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsProvider.notifier).fetchNotifications(),
        child: ListView.separated(
          padding: AppSpacing.paddingMd,
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            final isUnread = !notification.read;

            return InkWell(
              onTap: () async {
                final navigator = GoRouter.of(context);
                if (isUnread) {
                  await ref
                      .read(notificationsProvider.notifier)
                      .markAsRead(notification.id);
                }
                navigator.push('/tasks/${notification.taskId}');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: AppSpacing.md),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isUnread ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.message,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _formatDate(notification.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
