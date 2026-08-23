import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getStatusConfig() {
    switch (status.toLowerCase()) {
      case 'todo':
        return (AppColors.statusTodo, 'To Do');
      case 'in_progress':
        return (AppColors.statusInProgress, 'In Progress');
      case 'review':
        return (AppColors.statusReview, 'Review');
      case 'done':
        return (AppColors.statusDone, 'Done');
      default:
        return (AppColors.textSecondary, status);
    }
  }
}
