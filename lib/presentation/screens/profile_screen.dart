import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../providers/auth_notifier.dart';
import '../widgets/confirmation_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final authSession = ref.watch(authNotifierProvider).session;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          if (authSession != null) ...[
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Logged In As'),
              subtitle: Text('Role: ${authSession.role} • Org: ${authSession.orgId}'),
            ),
            const Divider(height: AppSpacing.xxl),
          ],
          SwitchListTile(
            title: const Text('Simulate Offline Mode'),
            subtitle: const Text('Force app to use cached data and disable network calls'),
            value: isOffline,
            onChanged: (val) {
              ref.read(isOfflineProvider.notifier).setOffline(val);
            },
          ),
          const Divider(height: AppSpacing.xxl),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => ConfirmationDialog(
                  title: 'Logout',
                  message: 'Are you sure you want to log out?',
                  confirmText: 'Logout',
                  isDestructive: true,
                  onConfirm: () {
                    ref.read(authNotifierProvider.notifier).logout();
                    Navigator.of(ctx).pop();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}