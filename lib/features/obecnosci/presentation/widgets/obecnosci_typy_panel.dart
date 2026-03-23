import 'package:flutter/material.dart';

class ObecnosciTypyPanel extends StatelessWidget {
  const ObecnosciTypyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final typy = <String>[
      'Sztab',
      'Loty',
      'Podróż służbowa',
      'Inne',
      'L4',
      'Służba',
      'Po służbie',
      'Urlop wypoczynkowy',
      'Urlop nagrodowy',
      'Urlop dodatkowy',
    ];

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
            'Typy obecności',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: typy.map((typ) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  typ,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}