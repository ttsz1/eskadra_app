import 'package:flutter/material.dart';

class LeaveRequestsPanel extends StatelessWidget {
  const LeaveRequestsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.30),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wnioski urlopowe',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const _LeaveRequestTile(
            imieNazwisko: 'Anna Nowak',
            zakres: '12.08.2026 - 16.08.2026',
            typ: 'Urlop nagrodowy',
            status: 'Oczekuje',
          ),
          const SizedBox(height: 8),
          const _LeaveRequestTile(
            imieNazwisko: 'Piotr Zieliński',
            zakres: '02.09.2026 - 06.09.2026',
            typ: 'Urlop wypoczynkowy',
            status: 'Do akceptacji',
          ),
          const SizedBox(height: 8),
          const _LeaveRequestTile(
            imieNazwisko: 'Jan Kowalski',
            zakres: '18.10.2026 - 20.10.2026',
            typ: 'Urlop dodatkowy',
            status: 'W przygotowaniu',
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestTile extends StatelessWidget {
  const _LeaveRequestTile({
    required this.imieNazwisko,
    required this.zakres,
    required this.typ,
    required this.status,
  });

  final String imieNazwisko;
  final String zakres;
  final String typ;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imieNazwisko,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$typ • $zakres',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}