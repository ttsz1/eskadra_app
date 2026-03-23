import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/attendance_provider.dart';
import 'attendance_entry_dialog.dart';

class ObecnosciPlanerPanel extends ConsumerWidget {
  const ObecnosciPlanerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: () async {
          final draft = await showAttendanceEntryDialog(context);
          if (draft == null) return;

          try {
            await ref.read(attendanceControllerProvider).createEntriesBatch(
              personIds: draft.personIds,
              dateFrom: draft.dateFrom,
              dateTo: draft.dateTo,
              repeatMode: draft.repeatMode,
              applyMonday: draft.applyMonday,
              applyTuesday: draft.applyTuesday,
              applyWednesday: draft.applyWednesday,
              applyThursday: draft.applyThursday,
              applyFriday: draft.applyFriday,
              applySaturday: draft.applySaturday,
              applySunday: draft.applySunday,
              attendanceType: draft.attendanceType,
              isAllDay: draft.isAllDay,
              timeFrom: draft.timeFrom,
              timeTo: draft.timeTo,
              note: draft.note,
            );

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Obecność została zapisana.'),
              ),
            );
          } catch (error) {
            if (!context.mounted) return;

            final message = error is AuthException
                ? error.message
                : error.toString().contains('Zakres godzin nakłada się')
                ? 'Zakres godzin nakłada się na istniejący wpis.'
                : error.toString().contains('istnieje już wpis w tym dniu')
                ? 'Dla tej osoby istnieje już wpis w tym dniu.'
                : 'Nie udało się zapisać obecności.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj obecność'),
      ),
    );
  }
}