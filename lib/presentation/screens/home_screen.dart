import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/primary_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/notifications_notifier.dart';
import '../providers/notifications_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final session = authState.session;

    // We also fetch notifications eagerly here so the badge is up to date
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
         ref.read(notificationsProvider.notifier).fetchNotifications();
      }
    });

    final notificationsState = ref.watch(notificationsProvider);
    int unreadCount = 0;
    if (notificationsState is NotificationsSuccess) {
      unreadCount = notificationsState.notifications.where((n) => !n.read).length;
    }

    // Show session-refresh snackbar when it arrives here
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.sessionWasRefreshed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Session refreshed silently'),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(authNotifierProvider.notifier).clearRefreshFlag();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskFlow',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings / Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              // Router guard will redirect to /login automatically
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.task_alt_rounded,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You are signed in!',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (session != null) ...[
                Text('Role: ${session.role}',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                Text('Org: ${session.orgId}',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Token expires: ${session.expiresAt.toLocal()}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () => context.push('/projects'),
                  text: 'View Projects',
                  icon: Icons.folder,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () => context.push('/tasks'),
                  text: 'My Tasks',
                  icon: Icons.check_circle,
                  isOutlined: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Inactivity-timeout info
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Auto-logout after 5 minutes of inactivity.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}