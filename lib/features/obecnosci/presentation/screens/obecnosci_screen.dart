import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/attendance_provider.dart';
import '../widgets/moje_obecnosci_panel.dart';
import '../widgets/obecnosci_planer_panel.dart';
import '../widgets/obecnosci_status_card.dart';
import '../widgets/obecnosci_weekly_grid.dart';

class ObecnosciScreen extends ConsumerWidget {
  const ObecnosciScreen({super.key});

  static const String routePath = '/attendance';
  static const String routeName = 'attendance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(attendanceTodaySummaryProvider);
    final weekStart = ref.watch(attendanceWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final presentCount = summaryAsync.maybeWhen(
      data: (data) => data.presentCount,
      orElse: () => 0,
    );

    final absentCount = summaryAsync.maybeWhen(
      data: (data) => data.absentCount,
      orElse: () => 0,
    );

    final missingCount = summaryAsync.maybeWhen(
      data: (data) => data.missingCount,
      orElse: () => 0,
    );

    final activePeopleCount = summaryAsync.maybeWhen(
      data: (data) => data.activePeopleCount,
      orElse: () => 0,
    );

    final weekLabel =
        '${DateFormat('dd.MM').format(weekStart)} - ${DateFormat('dd.MM.yyyy').format(weekEnd)}';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obecności',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tygodniowy podgląd pracy zespołu i edycja moich zgłoszonych obecności.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 210,
                  child: ObecnosciStatusCard(
                    tytul: 'Obecni dziś',
                    wartosc: '$presentCount/$activePeopleCount osób',
                    opis: 'Osoby oznaczone dziś jako będące w pracy.',
                    ikona: Icons.group_outlined,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: ObecnosciStatusCard(
                    tytul: 'Nieobecni dziś',
                    wartosc: '$absentCount/$activePeopleCount osób',
                    opis: 'Osoby oznaczone dziś jako nieobecne.',
                    ikona: Icons.person_off_outlined,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: ObecnosciStatusCard(
                    tytul: 'Brak zgłoszenia dziś',
                    wartosc: '$missingCount/$activePeopleCount osób',
                    opis: 'Aktywne osoby bez wpisu obecności na dziś.',
                    ikona: Icons.help_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(attendanceWeekStartProvider.notifier).state =
                        weekStart.subtract(const Duration(days: 7));
                  },
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Poprzedni tydzień',
                ),
                Text(
                  weekLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(attendanceWeekStartProvider.notifier).state =
                        weekStart.add(const Duration(days: 7));
                  },
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Następny tydzień',
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    ref.read(attendanceWeekStartProvider.notifier).state =
                        startOfWeek(DateTime.now());
                  },
                  child: const Text('Bieżący tydzień'),
                ),
                const Spacer(),
                const ObecnosciPlanerPanel(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1350;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          flex: 6,
                          child: ObecnosciWeeklyGrid(),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: MojeObecnosciPanel(),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    children: const [
                      SizedBox(
                        height: 520,
                        child: ObecnosciWeeklyGrid(),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 520,
                        child: MojeObecnosciPanel(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}