import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/task.dart';
import 'status_chip.dart';
import 'priority_chip.dart';
import 'avatar_with_name.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class TaskListItem extends ConsumerWidget {
  final AppTask task;
  final VoidCallback? onTap;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(status: task.status),
                  PriorityChip(priority: task.priority),
                  _buildAssignee(context, ref),
                  Text(
                    'Due: ${DateFormat.yMd().format(task.dueDate)}',
                    style: AppTextStyles.caption.copyWith(
                      color: task.dueDate.isBefore(DateTime.now())
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignee(BuildContext context, WidgetRef ref) {
    if (task.assigneeId == null) {
      return const AvatarWithName(
        name: 'Unassigned',
        radius: 12,
        nameStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    final membersAsync = ref.watch(orgMembersProvider);
    return membersAsync.when(
      data: (members) {
        final member = members.where((m) => m.id == task.assigneeId).firstOrNull;
        return AvatarWithName(
          name: member?.name ?? 'Unknown',
          avatarUrl: member?.avatarUrl,
          radius: 12,
          nameStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const AvatarWithName(
        name: 'Error',
        radius: 12,
        nameStyle: TextStyle(fontSize: 12, color: AppColors.error),
      ),
    );
  }
}
