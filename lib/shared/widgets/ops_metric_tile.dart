import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'ops_status_chip.dart';

class OpsMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final OpsStatusChip? status;

  const OpsMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: textTheme.headlineMedium),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: textTheme.bodySmall),
          ],
          if (status != null) ...[
            const SizedBox(height: AppSpacing.sm),
            status!,
          ],
        ],
      ),
    );
  }
}