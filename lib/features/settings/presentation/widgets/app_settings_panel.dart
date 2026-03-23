import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_provider.dart';
import '../../domain/models/admin_app_user.dart';
import '../providers/settings_providers.dart';

class AppSettingsPanel extends ConsumerWidget {
  const AppSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(appThemeControllerProvider);
    final isAdminAsync = ref.watch(isCurrentUserAdminProvider);

    return SizedBox(
      width: 960,
      height: 720,
      child: Row(
        children: [
          Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  'Ustawienia',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wygląd',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: themeController.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appThemeControllerProvider).setThemeMode(value);
                            }
                          },
                          title: const Text('Jasny'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: themeController.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appThemeControllerProvider).setThemeMode(value);
                            }
                          },
                          title: const Text('Ciemny'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          groupValue: themeController.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appThemeControllerProvider).setThemeMode(value);
                            }
                          },
                          title: const Text('Systemowy'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isAdminAsync.when(
                data: (isAdmin) {
                  if (!isAdmin) {
                    return const Center(
                      child: Text('Masz dostęp tylko do ustawień wyglądu.'),
                    );
                  }

                  return const _AdminUsersSection();
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Błąd ustawień: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUsersSection extends ConsumerWidget {
  const _AdminUsersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Użytkownicy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => const _CreateUserDialog(),
                );
                ref.invalidate(adminUsersProvider);
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Dodaj użytkownika'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Text('Brak użytkowników.'),
                );
              }

              final grouped = _groupUsersByOrg(users);

              return ListView(
                children: grouped.entries.map((entry) {
                  final orgKey = entry.key;
                  final orgUsers = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_2_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_EnumLabels.orgUnit(orgKey)} (${orgUsers.length})',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        ...orgUsers.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _UserTile(user: user),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Błąd użytkowników: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<AdminAppUser>> _groupUsersByOrg(List<AdminAppUser> users) {
    final map = <String, List<AdminAppUser>>{};

    for (final user in users) {
      final key = (user.orgUnit ?? '').trim().isEmpty
          ? 'unassigned'
          : user.orgUnit!.trim();

      map.putIfAbsent(key, () => []).add(user);
    }

    for (final entry in map.entries) {
      entry.value.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    }

    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'unassigned') return 1;
        if (b == 'unassigned') return -1;
        return _EnumLabels.orgUnit(a)
            .toLowerCase()
            .compareTo(_EnumLabels.orgUnit(b).toLowerCase());
      });

    return {
      for (final key in keys) key: map[key]!,
    };
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final AdminAppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName.characters.first.toUpperCase()
                : '?',
          ),
        ),
        title: Text(user.fullName),
        subtitle: Text(
          [
            user.email,
            if (user.orgFunction != null && user.orgFunction!.isNotEmpty)
              _EnumLabels.orgFunction(user.orgFunction!),
            if (user.personnelType != null && user.personnelType!.isNotEmpty)
              _EnumLabels.personnelType(user.personnelType!),
            if (user.rankGroup != null && user.rankGroup!.isNotEmpty)
              _EnumLabels.rankGroup(user.rankGroup!),
            user.isActive ? 'aktywny' : 'nieaktywny',
          ].join(' • '),
        ),
        trailing: IconButton(
          tooltip: 'Usuń użytkownika',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Usuń użytkownika'),
                    content: Text(
                      'Czy na pewno chcesz usunąć użytkownika ${user.fullName}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Anuluj'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Usuń'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!confirmed) return;

            try {
              await ref
                  .read(adminUserManagementRepositoryProvider)
                  .deleteUser(user.id);

              ref.invalidate(adminUsersProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Użytkownik został usunięty.'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Nie udało się usunąć użytkownika: $e',
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  String? _selectedOrgUnit;
  String? _selectedOrgFunction;
  String? _selectedPersonnelType;
  String? _selectedRankGroup;

  bool _isActive = true;
  bool _saving = false;

  static const _orgUnits = <String>[
    'command',
    'flight_training_section',
    'standardization_and_evaluation_section',
    'current_operations_section',
    'wys_rat_support_section',
    'trainer_device_support',
    'flight_training_subunit',
  ];

  static const _orgFunctions = <String>[
    'commander',
    'chief',
    'manager',
    'personnel',
  ];

  static const _personnelTypes = <String>[
    'pilot',
    'ground_staff',
  ];

  static const _rankGroups = <String>[
    'officer',
    'non_commissioned_officer',
    'enlisted',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podaj email, hasło i imię oraz nazwisko.'),
        ),
      );
      return;
    }

    if (_selectedOrgUnit == null ||
        _selectedOrgFunction == null ||
        _selectedPersonnelType == null ||
        _selectedRankGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz wszystkie wartości z list rozwijanych.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(adminUserManagementRepositoryProvider).createUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            orgUnit: _selectedOrgUnit,
            orgFunction: _selectedOrgFunction,
            personnelType: _selectedPersonnelType,
            rankGroup: _selectedRankGroup,
            isActive: _isActive,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się utworzyć użytkownika: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj użytkownika'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Imię i nazwisko',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Hasło startowe',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedOrgUnit,
                decoration: const InputDecoration(
                  labelText: 'Jednostka / sekcja',
                ),
                items: _orgUnits
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_EnumLabels.orgUnit(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedOrgUnit = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedOrgFunction,
                decoration: const InputDecoration(
                  labelText: 'Funkcja',
                ),
                items: _orgFunctions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_EnumLabels.orgFunction(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedOrgFunction = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPersonnelType,
                decoration: const InputDecoration(
                  labelText: 'Typ personelu',
                ),
                items: _personnelTypes
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_EnumLabels.personnelType(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedPersonnelType = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRankGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupa stopnia',
                ),
                items: _rankGroups
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_EnumLabels.rankGroup(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedRankGroup = value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                title: const Text('Aktywny'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Zapisywanie...' : 'Utwórz'),
        ),
      ],
    );
  }
}

class _EnumLabels {
  static String orgUnit(String value) {
    switch (value) {
      case 'command':
        return 'Dowództwo';
      case 'flight_training_section':
        return 'Sekcja szkolenia lotniczego';
      case 'standardization_and_evaluation_section':
        return 'Sekcja standaryzacji i oceny';
      case 'current_operations_section':
        return 'Sekcja operacji bieżących';
      case 'wys_rat_support_section':
        return 'Sekcja wsparcia WYS/RAT';
      case 'trainer_device_support':
        return 'Wsparcie urządzeń treningowych';
      case 'flight_training_subunit':
        return 'Pododdział szkolenia lotniczego';
      case 'unassigned':
        return 'Bez przypisanej sekcji';
      default:
        return value;
    }
  }

  static String orgFunction(String value) {
    switch (value) {
      case 'commander':
        return 'Dowódca';
      case 'chief':
        return 'Szef';
      case 'manager':
        return 'Kierownik';
      case 'personnel':
        return 'Personel';
      default:
        return value;
    }
  }

  static String personnelType(String value) {
    switch (value) {
      case 'pilot':
        return 'Pilot';
      case 'ground_staff':
        return 'Personel naziemny';
      default:
        return value;
    }
  }

  static String rankGroup(String value) {
    switch (value) {
      case 'officer':
        return 'Oficer';
      case 'non_commissioned_officer':
        return 'Podoficer';
      case 'enlisted':
        return 'Szeregowy';
      default:
        return value;
    }
  }
}
