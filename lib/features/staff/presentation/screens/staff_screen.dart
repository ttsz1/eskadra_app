import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/layout/ops_topbar.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../../../../shared/widgets/ops_status_chip.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const String routePath = '/staff';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OpsTopbar(
            title: 'Personnel control',
            subtitle: 'Zarządzanie personelem',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: OpsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OpsSectionHeader(
                      eyebrow: 'Staff',
                      title: 'Personel',
                      subtitle:
                      'Tu podłączymy listę operatorów, role, dostępność, statusy i przypisania.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: const [
                        OpsStatusChip(label: 'Gotowość', type: OpsStatusType.success),
                        OpsStatusChip(label: 'Poza zmianą', type: OpsStatusType.neutral),
                        OpsStatusChip(label: 'Brak obsady', type: OpsStatusType.error),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}