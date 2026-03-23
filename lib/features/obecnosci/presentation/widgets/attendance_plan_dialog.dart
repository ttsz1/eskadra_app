import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/attendance_plan.dart';
import '../providers/attendance_provider.dart';

class AttendancePlanDraft {
  const AttendancePlanDraft({
    required this.attendanceType,
    required this.dateFrom,
    required this.dateTo,
    required this.isAllDay,
    required this.timeFrom,
    required this.timeTo,
    required this.repeatMode,
    required this.applyMonday,
    required this.applyTuesday,
    required this.applyWednesday,
    required this.applyThursday,
    required this.applyFriday,
    required this.applySaturday,
    required this.applySunday,
    required this.note,
    required this.personIds,
  });

  final AttendanceType attendanceType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool isAllDay;
  final String? timeFrom;
  final String? timeTo;
  final bool repeatMode;
  final bool applyMonday;
  final bool applyTuesday;
  final bool applyWednesday;
  final bool applyThursday;
  final bool applyFriday;
  final bool applySaturday;
  final bool applySunday;
  final String note;
  final List<String> personIds;
}

Future<AttendancePlanDraft?> showAttendancePlanDialog(BuildContext context) {
  return showDialog<AttendancePlanDraft>(
    context: context,
    builder: (_) => const _AttendancePlanDialog(),
  );
}

class _AttendancePlanDialog extends ConsumerStatefulWidget {
  const _AttendancePlanDialog();

  @override
  ConsumerState<_AttendancePlanDialog> createState() =>
      _AttendancePlanDialogState();
}

class _AttendancePlanDialogState extends ConsumerState<_AttendancePlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  AttendanceType _selectedType = AttendanceType.sztab;
  DateTime _dateFrom = DateTime.now();
  DateTime _dateTo = DateTime.now();
  bool _isAllDay = false;
  bool _repeatMode = false;

  TimeOfDay _timeFrom = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _timeTo = const TimeOfDay(hour: 15, minute: 30);

  bool _monday = true;
  bool _tuesday = true;
  bool _wednesday = true;
  bool _thursday = true;
  bool _friday = true;
  bool _saturday = false;
  bool _sunday = false;

  final Set<String> _selectedPeopleIds = <String>{};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(attendancePeopleProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Dodaj wpis obecności'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AttendanceType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Typ obecności',
                  ),
                  items: AttendanceType.values
                      .map(
                        (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Data od',
                        value: _dateFrom,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateFrom,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );
                          if (picked == null) return;
                          setState(() {
                            _dateFrom = picked;
                            if (_dateTo.isBefore(_dateFrom)) {
                              _dateTo = _dateFrom;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Data do',
                        value: _dateTo,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateTo,
                            firstDate: _dateFrom,
                            lastDate: DateTime(2035),
                          );
                          if (picked == null) return;
                          setState(() {
                            _dateTo = picked;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cały dzień'),
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() {
                      _isAllDay = value;
                    });
                  },
                ),
                if (!_isAllDay) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Godzina od',
                          value: _timeFrom,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _timeFrom,
                            );
                            if (picked == null) return;
                            setState(() {
                              _timeFrom = picked;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'Godzina do',
                          value: _timeTo,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _timeTo,
                            );
                            if (picked == null) return;
                            setState(() {
                              _timeTo = picked;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Wpis seryjny'),
                  subtitle: const Text(
                    'Jeśli włączone, plan będzie stosowany tylko dla wybranych dni tygodnia w zakresie dat.',
                  ),
                  value: _repeatMode,
                  onChanged: (value) {
                    setState(() {
                      _repeatMode = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _weekdayChip('Pn', _monday, (v) => setState(() => _monday = v)),
                    _weekdayChip('Wt', _tuesday, (v) => setState(() => _tuesday = v)),
                    _weekdayChip('Śr', _wednesday, (v) => setState(() => _wednesday = v)),
                    _weekdayChip('Cz', _thursday, (v) => setState(() => _thursday = v)),
                    _weekdayChip('Pt', _friday, (v) => setState(() => _friday = v)),
                    _weekdayChip('Sb', _saturday, (v) => setState(() => _saturday = v)),
                    _weekdayChip('Nd', _sunday, (v) => setState(() => _sunday = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Osoby',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                peopleAsync.when(
                  data: (people) {
                    if (people.isEmpty) {
                      return const Text('Brak aktywnych profili.');
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: people.map((person) {
                        final selected = _selectedPeopleIds.contains(person.id);
                        return FilterChip(
                          selected: selected,
                          label: Text(person.fullName),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedPeopleIds.add(person.id);
                              } else {
                                _selectedPeopleIds.remove(person.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Text('Błąd ładowania personelu: $error'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    alignLabelWithHint: true,
                    hintText: 'Np. obsada stanowiska sztabowego',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Zapisz'),
        ),
      ],
    );
  }

  Widget _weekdayChip(
      String label,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPeopleIds.isEmpty) {
      _showError('Wybierz przynajmniej jedną osobę.');
      return;
    }

    if (!_isAllDay && !_isValidTimeRange(_timeFrom, _timeTo)) {
      _showError('Godzina końcowa musi być późniejsza niż początkowa.');
      return;
    }

    if (_repeatMode &&
        !(_monday ||
            _tuesday ||
            _wednesday ||
            _thursday ||
            _friday ||
            _saturday ||
            _sunday)) {
      _showError('Dla wpisu seryjnego zaznacz co najmniej jeden dzień tygodnia.');
      return;
    }

    Navigator.of(context).pop(
      AttendancePlanDraft(
        attendanceType: _selectedType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        isAllDay: _isAllDay,
        timeFrom: _isAllDay ? null : _formatTime(_timeFrom),
        timeTo: _isAllDay ? null : _formatTime(_timeTo),
        repeatMode: _repeatMode,
        applyMonday: _monday,
        applyTuesday: _tuesday,
        applyWednesday: _wednesday,
        applyThursday: _thursday,
        applyFriday: _friday,
        applySaturday: _saturday,
        applySunday: _sunday,
        note: _noteController.text.trim(),
        personIds: _selectedPeopleIds.toList(),
      ),
    );
  }

  bool _isValidTimeRange(TimeOfDay from, TimeOfDay to) {
    final fromMinutes = from.hour * 60 + from.minute;
    final toMinutes = to.hour * 60 + to.minute;
    return toMinutes > fromMinutes;
  }

  String _formatTime(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(text),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(text),
      ),
    );
  }
}