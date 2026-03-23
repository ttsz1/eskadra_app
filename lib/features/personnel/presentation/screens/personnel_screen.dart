import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../providers/personnel_module_provider.dart';
import '../widgets/personnel_detail_panel.dart';
import '../widgets/personnel_structure_panel.dart';

class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  static const String routePath = '/personnel';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileDirectoryProvider);
    final currentUser = ref.watch(currentAppPersonProvider);
    final notifier = ref.read(personnelModuleProvider.notifier);

    profilesAsync.whenData((profiles) {
      notifier.syncProfiles(profiles, currentUser);
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: profilesAsync.when(
          data: (_) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1100;

                if (compact) {
                  return const Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: PersonnelStructurePanel(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Expanded(
                        flex: 6,
                        child: PersonnelDetailPanel(),
                      ),
                    ],
                  );
                }

                return const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: PersonnelStructurePanel(),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 6,
                      child: PersonnelDetailPanel(),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const OpsPanel(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => OpsPanel(
            child: Center(child: Text('Błąd ładowania personelu: $error')),
          ),
        ),
      ),
    );
  }
}