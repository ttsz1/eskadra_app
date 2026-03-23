import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';
import '../../domain/models/calendar_mode.dart';
import '../providers/calendar_providers.dart';
import '../utils/calendar_person_label.dart';

class CalendarFiltersDialog extends ConsumerStatefulWidget {
  const CalendarFiltersDialog({super.key});

  @override
  ConsumerState<CalendarFiltersDialog> createState() =>
      _CalendarFiltersDialogState();
}

class _CalendarFiltersDialogState
    extends ConsumerState<CalendarFiltersDialog> {
  final TextEditingController _personSearchController = TextEditingController();
  String _personQuery = '';

  @override
  void dispose() {
    _personSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(calendarControllerProvider.notifier);
    final state = ref.watch(calendarControllerProvider);
    final filters = state.filters;
    final theme = Theme.of(context);

    final personOptions = _buildPersonOptions(state.items);
    final filteredPeople = personOptions.where((person) {
      if (_personQuery.trim().isEmpty) return true;

      final query = _personQuery.trim().toLowerCase();
      return person.label.toLowerCase().contains(query) ||
          person.id.toLowerCase().contains(query);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 820,
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Filtry kalendarza',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle('Tryb'),
                  ...CalendarMode.values.map(
                        (mode) => RadioListTile<CalendarMode>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_modeLabel(mode)),
                      value: mode,
                      groupValue: filters.mode,
                      onChanged: (value) async {
                        if (value == null) return;
                        await controller.updateFilters(
                          filters.copyWith(mode: value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Warstwy'),
                  ...CalendarLayer.values.map((layer) {
                    final enabled = filters.layers.contains(layer);

                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_layerLabel(layer)),
                      value: enabled,
                      onChanged: (value) async {
                        final newLayers = Set<CalendarLayer>.from(filters.layers);

                        if (value == true) {
                          newLayers.add(layer);
                        } else {
                          newLayers.remove(layer);
                        }

                        await controller.updateFilters(
                          filters.copyWith(layers: newLayers),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  const _SectionTitle('Osoby'),
                  TextField(
                    controller: _personSearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: 'Szukaj osoby po nazwie lub ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _personQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await controller.updateFilters(
                            filters.copyWith(personIds: <String>{}),
                          );
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Wyczyść wybór'),
                      ),
                      OutlinedButton.icon(
                        onPressed: filteredPeople.isEmpty
                            ? null
                            : () async {
                          await controller.updateFilters(
                            filters.copyWith(
                              personIds: filteredPeople
                                  .map((e) => e.id)
                                  .toSet(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.select_all),
                        label: const Text('Zaznacz widoczne'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.25),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: filteredPeople.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Brak osób do wyświetlenia'),
                      ),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredPeople.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.20),
                      ),
                      itemBuilder: (context, index) {
                        final person = filteredPeople[index];
                        final selected =
                        filters.personIds.contains(person.id);

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          value: selected,
                          title: Text(
                            person.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            person.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          onChanged: (value) async {
                            final newIds =
                            Set<String>.from(filters.personIds);

                            if (value == true) {
                              newIds.add(person.id);
                            } else {
                              newIds.remove(person.id);
                            }

                            await controller.updateFilters(
                              filters.copyWith(personIds: newIds),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Widoczność'),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pokaż weekendy'),
                    value: filters.showWeekends,
                    onChanged: (value) async {
                      await controller.updateFilters(
                        filters.copyWith(showWeekends: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pokaż święta PL'),
                    value: filters.showPolishHolidays,
                    onChanged: (value) async {
                      await controller.updateFilters(
                        filters.copyWith(showPolishHolidays: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pokaż nieprzypisane'),
                    value: filters.showUnassignedItems,
                    onChanged: (value) async {
                      await controller.updateFilters(
                        filters.copyWith(showUnassignedItems: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tylko krytyczne'),
                    value: filters.onlyCritical,
                    onChanged: (value) async {
                      await controller.updateFilters(
                        filters.copyWith(onlyCritical: value),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await controller.updateFilters(
                        calendarDefaultFilters,
                      );
                    },
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zamknij'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PersonOption> _buildPersonOptions(List<CalendarItem> items) {
    final map = <String, _PersonOption>{};

    for (final item in items) {
      final personId = item.personId?.trim();
      if (personId == null || personId.isEmpty) continue;

      map[personId] = _PersonOption(
        id: personId,
        label: calendarPersonLabel(
          personName: item.personName,
          personId: personId,
        ),
      );
    }

    final result = map.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return result;
  }

  String _modeLabel(CalendarMode mode) {
    switch (mode) {
      case CalendarMode.operations:
        return 'Operacyjny';
      case CalendarMode.leavePlanner:
        return 'Planowanie urlopów';
      case CalendarMode.attendance:
        return 'Obecności';
      case CalendarMode.tasksAndDeadlines:
        return 'Zadania / terminy';
    }
  }

  String _layerLabel(CalendarLayer layer) {
    switch (layer) {
      case CalendarLayer.tasks:
        return 'Zadania';
      case CalendarLayer.deadlines:
        return 'Terminy';
      case CalendarLayer.events:
        return 'Wydarzenia';
      case CalendarLayer.attendance:
        return 'Obecności';
      case CalendarLayer.plannedLeave:
        return 'Planowany urlop';
      case CalendarLayer.requestedLeave:
        return 'Wnioskowany urlop';
      case CalendarLayer.unassignedItems:
        return 'Nieprzypisane';
    }
  }
}

class _PersonOption {
  final String id;
  final String label;

  const _PersonOption({
    required this.id,
    required this.label,
  });
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}