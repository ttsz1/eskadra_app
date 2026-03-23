import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/models/org_structure.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../../../../shared/widgets/ops_status_chip.dart';
import '../providers/personnel_module_provider.dart';

class PersonnelStructurePanel extends ConsumerWidget {
  const PersonnelStructurePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personnelModuleProvider);
    final notifier = ref.read(personnelModuleProvider.notifier);
    final profiles = state.profiles;

    final grouped = <OrgUnit, List<AppPerson>>{
      for (final unit in OrgUnit.values)
        unit: profiles.where((p) => p.unit == unit).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName)),
    };

    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OpsSectionHeader(
            eyebrow: 'Personnel structure',
            title: 'Struktura personelu',
            subtitle:
            'Układ sekcji i komórek zgodny ze schematem organizacyjnym.',
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              children: OrgUnit.values.map((unit) {
                final people = grouped[unit] ?? const <AppPerson>[];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              unit.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          OpsStatusChip(
                            label: '${people.length} os.',
                            type: OpsStatusType.info,
                          ),
                        ],
                      ),
                      children: people.isEmpty
                          ? [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Brak przypisanych osób.'),
                          ),
                        ),
                      ]
                          : people.map((person) {
                        final selected = state.selectedPersonId == person.id;

                        return ListTile(
                          selected: selected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          title: Text(person.fullName),
                          subtitle: Text(
                            '${person.function.label} • ${person.personnelType.label} • ${person.rankGroup.label}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => notifier.selectPerson(person.id),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}