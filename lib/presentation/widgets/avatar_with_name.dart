import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AvatarWithName extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final bool showName;
  final TextStyle? nameStyle;

  const AvatarWithName({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 16,
    this.showName = true,
    this.nameStyle,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.9,
                  ),
                )
              : null,
        ),
        if (showName) ...[
          SizedBox(width: radius * 0.5),
          Text(
            name,
            style: nameStyle ?? AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
