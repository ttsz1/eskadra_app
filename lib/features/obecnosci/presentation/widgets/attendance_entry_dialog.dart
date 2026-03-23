import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/attendance_entry.dart';
import '../providers/attendance_provider.dart';

bool _forcesAllDay(AttendanceType type) {
  switch (type) {
    case AttendanceType.urlopWypoczynkowy:
    case AttendanceType.urlopNagrodowy:
    case AttendanceType.urlopDodatkowy:
    case AttendanceType.l4:
    case AttendanceType.podrozSluzbowa:
      return true;
    case AttendanceType.sztab:
    case AttendanceType.loty:
    case AttendanceType.inne:
    case AttendanceType.sluzba:
    case AttendanceType.poSluzbie:
      return false;
  }
}

class AttendanceEntryDraft {
  const AttendanceEntryDraft({
    required this.personIds,
    required this.dateFrom,
    required this.dateTo,
    required this.repeatMode,
    required this.applyMonday,
    required this.applyTuesday,
    required this.applyWednesday,
    required this.applyThursday,
    required this.applyFriday,
    required this.applySaturday,
    required this.applySunday,
    required this.attendanceType,
    required this.isAllDay,
    required this.timeFrom,
    required this.timeTo,
    required this.note,
  });

  final List<String> personIds;
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool repeatMode;
  final bool applyMonday;
  final bool applyTuesday;
  final bool applyWednesday;
  final bool applyThursday;
  final bool applyFriday;
  final bool applySaturday;
  final bool applySunday;
  final AttendanceType attendanceType;
  final bool isAllDay;
  final String? timeFrom;
  final String? timeTo;
  final String note;
}

Future<AttendanceEntryDraft?> showAttendanceEntryDialog(
    BuildContext context, {
      AttendanceEntry? existingEntry,
      String? fixedPersonId,
      String? fixedPersonLabel,
      DateTime? initialDate,
    }) {
  return showDialog<AttendanceEntryDraft>(
    context: context,
    builder: (_) => _AttendanceEntryDialog(
      existingEntry: existingEntry,
      fixedPersonId: fixedPersonId,
      fixedPersonLabel: fixedPersonLabel,
      initialDate: initialDate,
    ),
  );
}

class _AttendanceEntryDialog extends ConsumerStatefulWidget {
  const _AttendanceEntryDialog({
    this.existingEntry,
    this.fixedPersonId,
    this.fixedPersonLabel,
    this.initialDate,
  });

  final AttendanceEntry? existingEntry;
  final String? fixedPersonId;
  final String? fixedPersonLabel;
  final DateTime? initialDate;

  @override
  ConsumerState<_AttendanceEntryDialog> createState() =>
      _AttendanceEntryDialogState();
}

class _AttendanceEntryDialogState extends ConsumerState<_AttendanceEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  late AttendanceType _selectedType;
  late DateTime _dateFrom;
  late DateTime _dateTo;
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

  bool get _isEditMode => widget.existingEntry != null;
  bool get _isSinglePersonMode => widget.fixedPersonId != null || _isEditMode;
  bool get _isForcedAllDayType => _forcesAllDay(_selectedType);

  @override
  void initState() {
    super.initState();

    final existing = widget.existingEntry;
    final baseDate = widget.initialDate ?? DateTime.now();

    _selectedType = existing?.attendanceType ?? AttendanceType.sztab;
    _dateFrom = existing?.attendanceDate ?? baseDate;
    _dateTo = existing?.attendanceDate ?? baseDate;
    _isAllDay = _forcesAllDay(existing?.attendanceType ?? AttendanceType.sztab)
        ? true
        : (existing?.isAllDay ?? false);
    _noteController.text = existing?.note ?? '';

    if (existing?.timeFrom != null) {
      _timeFrom = _parseTime(existing!.timeFrom!);
    }
    if (existing?.timeTo != null) {
      _timeTo = _parseTime(existing!.timeTo!);
    }

    if (widget.fixedPersonId != null) {
      _selectedPeopleIds.add(widget.fixedPersonId!);
    }
    if (existing != null) {
      _selectedPeopleIds.add(existing.personId);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(attendancePeopleProvider);

    return AlertDialog(
      title: Text(_isEditMode ? 'Edytuj obecność' : 'Dodaj obecność'),
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
                      if (_forcesAllDay(value)) {
                        _isAllDay = true;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_isSinglePersonMode)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Osoba',
                    ),
                    child: Text(
                      widget.fixedPersonLabel ?? 'Wybrana osoba',
                    ),
                  )
                else
                  peopleAsync.when(
                    data: (people) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: people.map((person) {
                          final selected =
                          _selectedPeopleIds.contains(person.id);
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
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) =>
                        Text('Błąd ładowania personelu: $error'),
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
                        onTap: _isEditMode
                            ? null
                            : () async {
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
                  value: _isForcedAllDayType ? true : _isAllDay,
                  onChanged: _isForcedAllDayType
                      ? null
                      : (value) {
                    setState(() {
                      _isAllDay = value;
                    });
                  },
                ),
                if (!(_isForcedAllDayType || _isAllDay)) ...[
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
                if (!_isEditMode) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Twórz jako wpis seryjny'),
                    subtitle: const Text(
                      'Jeśli włączone, wpis zostanie utworzony tylko dla wybranych dni tygodnia w zakresie dat.',
                    ),
                    value: _repeatMode,
                    onChanged: (value) {
                      setState(() {
                        _repeatMode = value;
                      });
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _weekdayChip(
                          'Pn', _monday, (v) => setState(() => _monday = v)),
                      _weekdayChip(
                          'Wt', _tuesday, (v) => setState(() => _tuesday = v)),
                      _weekdayChip(
                          'Śr', _wednesday, (v) => setState(() => _wednesday = v)),
                      _weekdayChip(
                          'Cz', _thursday, (v) => setState(() => _thursday = v)),
                      _weekdayChip(
                          'Pt', _friday, (v) => setState(() => _friday = v)),
                      _weekdayChip(
                          'Sb', _saturday, (v) => setState(() => _saturday = v)),
                      _weekdayChip(
                          'Nd', _sunday, (v) => setState(() => _sunday = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    alignLabelWithHint: true,
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
          child: Text(_isEditMode ? 'Zapisz zmiany' : 'Dodaj'),
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

    if (!(_isForcedAllDayType || _isAllDay) &&
        !_isValidTimeRange(_timeFrom, _timeTo)) {
      _showError('Godzina końcowa musi być późniejsza niż początkowa.');
      return;
    }

    if (!_isEditMode &&
        _repeatMode &&
        !(_monday ||
            _tuesday ||
            _wednesday ||
            _thursday ||
            _friday ||
            _saturday ||
            _sunday)) {
      _showError(
        'Dla wpisu seryjnego zaznacz co najmniej jeden dzień tygodnia.',
      );
      return;
    }

    Navigator.of(context).pop(
      AttendanceEntryDraft(
        personIds: _selectedPeopleIds.toList(),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        repeatMode: _isEditMode ? false : _repeatMode,
        applyMonday: _monday,
        applyTuesday: _tuesday,
        applyWednesday: _wednesday,
        applyThursday: _thursday,
        applyFriday: _friday,
        applySaturday: _saturday,
        applySunday: _sunday,
        attendanceType: _selectedType,
        isAllDay: _isForcedAllDayType ? true : _isAllDay,
        timeFrom:
        (_isForcedAllDayType || _isAllDay) ? null : _formatTime(_timeFrom),
        timeTo:
        (_isForcedAllDayType || _isAllDay) ? null : _formatTime(_timeTo),
        note: _noteController.text.trim(),
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

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return const TimeOfDay(hour: 7, minute: 30);
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 30,
    );
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
  final VoidCallback? onTap;

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