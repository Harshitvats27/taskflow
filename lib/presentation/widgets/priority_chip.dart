import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _getPriorityConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getPriorityConfig() {
    switch (priority.toLowerCase()) {
      case 'low':
        return (AppColors.priorityLow, 'Low', Icons.arrow_downward_rounded);
      case 'medium':
        return (AppColors.priorityMedium, 'Medium', Icons.remove_rounded);
      case 'high':
        return (AppColors.priorityHigh, 'High', Icons.arrow_upward_rounded);
      case 'urgent':
        return (AppColors.priorityUrgent, 'Urgent', Icons.warning_rounded);
      default:
        return (AppColors.textSecondary, priority, Icons.help_outline);
    }
  }
}
