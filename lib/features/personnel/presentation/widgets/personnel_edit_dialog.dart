import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/models/org_structure.dart';
import '../providers/personnel_module_provider.dart';

Future<void> showPersonnelEditDialog(
    BuildContext context,
    WidgetRef ref, {
      required AppPerson person,
    }) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 760,
        height: 640,
        child: PersonnelEditDialog(person: person),
      ),
    ),
  );
}

class PersonnelEditDialog extends ConsumerStatefulWidget {
  final AppPerson person;

  const PersonnelEditDialog({
    super.key,
    required this.person,
  });

  @override
  ConsumerState<PersonnelEditDialog> createState() =>
      _PersonnelEditDialogState();
}

class _PersonnelEditDialogState extends ConsumerState<PersonnelEditDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;

  late OrgUnit _unit;
  late OrgFunction _function;
  late PersonnelType _personnelType;
  late RankGroup _rankGroup;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(text: widget.person.fullName);
    _emailController = TextEditingController(text: widget.person.email);
    _unit = widget.person.unit;
    _function = widget.person.function;
    _personnelType = widget.person.personnelType;
    _rankGroup = widget.person.rankGroup;
    _isActive = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(personnelModuleProvider.notifier).updatePerson(
      id: widget.person.id,
      fullName: _fullNameController.text,
      email: _emailController.text,
      unit: _unit,
      function: _function,
      personnelType: _personnelType,
      rankGroup: _rankGroup,
      isActive: _isActive,
    );

    final state = ref.read(personnelModuleProvider);
    if (state.error != null) return;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personnelModuleProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EDYTUJ OSOBĘ',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Korekta danych personalnych',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Imię i nazwisko',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<OrgUnit>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Sekcja / komórka',
                    ),
                    items: OrgUnit.values
                        .map(
                          (item) => DropdownMenuItem<OrgUnit>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _unit = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<OrgFunction>(
                    value: _function,
                    decoration: const InputDecoration(
                      labelText: 'Funkcja',
                    ),
                    items: OrgFunction.values
                        .map(
                          (item) => DropdownMenuItem<OrgFunction>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _function = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PersonnelType>(
                    value: _personnelType,
                    decoration: const InputDecoration(
                      labelText: 'Typ personelu',
                    ),
                    items: PersonnelType.values
                        .map(
                          (item) => DropdownMenuItem<PersonnelType>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _personnelType = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<RankGroup>(
                    value: _rankGroup,
                    decoration: const InputDecoration(
                      labelText: 'Korpus',
                    ),
                    items: RankGroup.values
                        .map(
                          (item) => DropdownMenuItem<RankGroup>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _rankGroup = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: const Text('Aktywny profil'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed:
                state.isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: state.isSaving ? null : _submit,
                child: state.isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Zapisz zmiany'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}