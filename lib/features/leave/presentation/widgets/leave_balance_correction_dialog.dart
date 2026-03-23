import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/leave_year_balance.dart';
import '../providers/leave_providers.dart';

class LeaveBalanceCorrectionDialog extends ConsumerStatefulWidget {
  const LeaveBalanceCorrectionDialog({
    super.key,
    required this.targetYear,
  });

  final int targetYear;

  @override
  ConsumerState<LeaveBalanceCorrectionDialog> createState() =>
      _LeaveBalanceCorrectionDialogState();
}

class _LeaveBalanceCorrectionDialogState
    extends ConsumerState<LeaveBalanceCorrectionDialog> {
  late final TextEditingController _olderVacationController;
  late final TextEditingController _olderAdditionalController;
  late final TextEditingController _minus3VacationController;
  late final TextEditingController _minus3AdditionalController;
  late final TextEditingController _minus2VacationController;
  late final TextEditingController _minus2AdditionalController;
  late final TextEditingController _minus1VacationController;
  late final TextEditingController _minus1AdditionalController;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _olderVacationController = TextEditingController();
    _olderAdditionalController = TextEditingController();
    _minus3VacationController = TextEditingController();
    _minus3AdditionalController = TextEditingController();
    _minus2VacationController = TextEditingController();
    _minus2AdditionalController = TextEditingController();
    _minus1VacationController = TextEditingController();
    _minus1AdditionalController = TextEditingController();
  }

  @override
  void dispose() {
    _olderVacationController.dispose();
    _olderAdditionalController.dispose();
    _minus3VacationController.dispose();
    _minus3AdditionalController.dispose();
    _minus2VacationController.dispose();
    _minus2AdditionalController.dispose();
    _minus1VacationController.dispose();
    _minus1AdditionalController.dispose();
    super.dispose();
  }

  void _fillFromBalances(List<LeaveYearBalance> balances) {
    if (_initialized) return;
    _initialized = true;

    final older = _sumForYearOrOlder(
      balances,
      year: widget.targetYear - 4,
      olderOnly: true,
    );
    final y3 = _sumForYearOrOlder(
      balances,
      year: widget.targetYear - 3,
      olderOnly: false,
    );
    final y2 = _sumForYearOrOlder(
      balances,
      year: widget.targetYear - 2,
      olderOnly: false,
    );
    final y1 = _sumForYearOrOlder(
      balances,
      year: widget.targetYear - 1,
      olderOnly: false,
    );

    _olderVacationController.text = older.$1.toString();
    _olderAdditionalController.text = older.$2.toString();
    _minus3VacationController.text = y3.$1.toString();
    _minus3AdditionalController.text = y3.$2.toString();
    _minus2VacationController.text = y2.$1.toString();
    _minus2AdditionalController.text = y2.$2.toString();
    _minus1VacationController.text = y1.$1.toString();
    _minus1AdditionalController.text = y1.$2.toString();
  }

  (int, int) _sumForYearOrOlder(
      List<LeaveYearBalance> balances, {
        required int year,
        required bool olderOnly,
      }) {
    final filtered = balances.where((item) {
      if (item.source != 'manual') return false;
      if (olderOnly) return item.year <= year;
      return item.year == year;
    });

    var vacation = 0;
    var additional = 0;
    for (final item in filtered) {
      vacation += item.vacationDays;
      additional += item.additionalDays;
    }
    return (vacation, additional);
  }

  int _toInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      await ref.read(leaveActionsProvider).saveBalance(
        year: widget.targetYear - 4,
        vacationDays: _toInt(_olderVacationController),
        additionalDays: _toInt(_olderAdditionalController),
        source: 'manual',
      );
      await ref.read(leaveActionsProvider).saveBalance(
        year: widget.targetYear - 3,
        vacationDays: _toInt(_minus3VacationController),
        additionalDays: _toInt(_minus3AdditionalController),
        source: 'manual',
      );
      await ref.read(leaveActionsProvider).saveBalance(
        year: widget.targetYear - 2,
        vacationDays: _toInt(_minus2VacationController),
        additionalDays: _toInt(_minus2AdditionalController),
        source: 'manual',
      );
      await ref.read(leaveActionsProvider).saveBalance(
        year: widget.targetYear - 1,
        vacationDays: _toInt(_minus1VacationController),
        additionalDays: _toInt(_minus1AdditionalController),
        source: 'manual',
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać korekty: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync =
    ref.watch(leavePlanningBalancesProvider(widget.targetYear));

    return AlertDialog(
      title: Text('Korekta dni za poprzednie lata (${widget.targetYear})'),
      content: SizedBox(
        width: 920,
        child: balancesAsync.when(
          data: (balances) {
            _fillFromBalances(balances);

            return SingleChildScrollView(
              child: Column(
                children: [
                  _row(
                    leftLabel: 'Wypoczynkowy wcześniejsze lata',
                    leftController: _olderVacationController,
                    rightLabel: 'Dodatkowy wcześniejsze lata',
                    rightController: _olderAdditionalController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _row(
                    leftLabel:
                    'Wypoczynkowy rok ${widget.targetYear - 3}',
                    leftController: _minus3VacationController,
                    rightLabel:
                    'Dodatkowy rok ${widget.targetYear - 3}',
                    rightController: _minus3AdditionalController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _row(
                    leftLabel:
                    'Wypoczynkowy rok ${widget.targetYear - 2}',
                    leftController: _minus2VacationController,
                    rightLabel:
                    'Dodatkowy rok ${widget.targetYear - 2}',
                    rightController: _minus2AdditionalController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _row(
                    leftLabel:
                    'Wypoczynkowy rok ${widget.targetYear - 1}',
                    leftController: _minus1VacationController,
                    rightLabel:
                    'Dodatkowy rok ${widget.targetYear - 1}',
                    rightController: _minus1AdditionalController,
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 200,
            child: Center(child: Text('Błąd korekty salda: $error')),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save_outlined),
          label: const Text('Zapisz'),
        ),
      ],
    );
  }

  Widget _row({
    required String leftLabel,
    required TextEditingController leftController,
    required String rightLabel,
    required TextEditingController rightController,
  }) {
    return Row(
      children: [
        Expanded(
          child: _fieldCard(
            label: leftLabel,
            controller: leftController,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _fieldCard(
            label: rightLabel,
            controller: rightController,
          ),
        ),
      ],
    );
  }

  Widget _fieldCard({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '0',
            ),
          ),
        ],
      ),
    );
  }
}