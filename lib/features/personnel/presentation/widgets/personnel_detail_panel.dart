import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/models/org_structure.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../providers/personnel_module_provider.dart';
import 'personnel_edit_dialog.dart';

class PersonnelDetailPanel extends ConsumerWidget {
  const PersonnelDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personnelModuleProvider);
    final notifier = ref.read(personnelModuleProvider.notifier);
    final person = state.selectedPerson;

    if (person == null) {
      return const OpsPanel(
        child: Center(child: Text('Wybierz osobę ze struktury.')),
      );
    }

    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSectionHeader(
            eyebrow: 'Personnel detail',
            title: person.fullName,
            subtitle: '${person.unit.label} • ${person.function.label}',
            trailing: notifier.canManageProfiles
                ? FilledButton.icon(
              onPressed: () => showPersonnelEditDialog(
                context,
                ref,
                person: person,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edytuj'),
            )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _InfoCard(label: 'Imię i nazwisko', value: person.fullName),
              _InfoCard(label: 'E-mail', value: person.email),
              _InfoCard(label: 'Sekcja / komórka', value: person.unit.label),
              _InfoCard(label: 'Funkcja', value: person.function.label),
              _InfoCard(
                label: 'Typ personelu',
                value: person.personnelType.label,
              ),
              _InfoCard(label: 'Korpus', value: person.rankGroup.label),
              _InfoCard(label: 'ID systemowe', value: person.id),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Karta personalna',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tu później możemy dodać dodatkowe pola: telefon, uwagi, status dostępności, kwalifikacje, uprawnienia, daty szkoleń, dokumenty i historię zmian.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}