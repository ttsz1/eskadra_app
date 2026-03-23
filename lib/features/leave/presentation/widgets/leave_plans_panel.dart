import 'package:flutter/material.dart';

class LeavePlansPanel extends StatelessWidget {
  const LeavePlansPanel({super.key});

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
            'Planowane urlopy',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const _LeavePlanRow(
            imieNazwisko: 'Tomasz Wójcik',
            zakres: '01.07.2026 - 10.07.2026',
            typ: 'Urlop wypoczynkowy',
          ),
          const Divider(height: 20),
          const _LeavePlanRow(
            imieNazwisko: 'Marek Wiśniewski',
            zakres: '21.07.2026 - 25.07.2026',
            typ: 'Urlop dodatkowy',
          ),
          const Divider(height: 20),
          const _LeavePlanRow(
            imieNazwisko: 'Anna Nowak',
            zakres: '04.08.2026 - 08.08.2026',
            typ: 'Urlop nagrodowy',
          ),
        ],
      ),
    );
  }
}

class _LeavePlanRow extends StatelessWidget {
  const _LeavePlanRow({
    required this.imieNazwisko,
    required this.zakres,
    required this.typ,
  });

  final String imieNazwisko;
  final String zakres;
  final String typ;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.beach_access_outlined,
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
      ],
    );
  }
}