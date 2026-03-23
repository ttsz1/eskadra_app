import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

enum OpsStatusType {
  neutral,
  info,
  success,
  warning,
  error,
}

class OpsStatusChip extends StatelessWidget {
  final String label;
  final OpsStatusType type;

  const OpsStatusChip({
    super.key,
    required this.label,
    this.type = OpsStatusType.neutral,
  });

  Color _background(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case OpsStatusType.info:
        return isDark ? AppColors.darkOverlay : AppColors.lightOverlay;
      case OpsStatusType.success:
        return isDark
            ? AppColors.darkSuccess.withValues(alpha: 0.14)
            : AppColors.lightSuccess.withValues(alpha: 0.12);
      case OpsStatusType.warning:
        return isDark
            ? AppColors.darkWarning.withValues(alpha: 0.14)
            : AppColors.lightWarning.withValues(alpha: 0.12);
      case OpsStatusType.error:
        return isDark
            ? AppColors.darkError.withValues(alpha: 0.14)
            : AppColors.lightError.withValues(alpha: 0.12);
      case OpsStatusType.neutral:
        return isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    }
  }

  Color _foreground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case OpsStatusType.info:
        return isDark ? AppColors.darkInfo : AppColors.lightInfo;
      case OpsStatusType.success:
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case OpsStatusType.warning:
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case OpsStatusType.error:
        return isDark ? AppColors.darkError : AppColors.lightError;
      case OpsStatusType.neutral:
        return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _foreground(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _background(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}