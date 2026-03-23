import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../widgets/ops_status_chip.dart';

class OpsTopbar extends StatelessWidget {
  final String title;
  final String subtitle;

  const OpsTopbar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                const Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OpsStatusChip(
                      label: 'Sync online',
                      type: OpsStatusType.success,
                    ),
                    OpsStatusChip(
                      label: 'unclasyfied',
                      type: OpsStatusType.info,
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OpsStatusChip(
                    label: 'Sync online',
                    type: OpsStatusType.success,
                  ),
                  OpsStatusChip(
                    label: 'unclasyfied',
                    type: OpsStatusType.info,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}