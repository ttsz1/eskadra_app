import 'package:flutter/material.dart';

class LeaveAssistantPanel extends StatelessWidget {
  const LeaveAssistantPanel({super.key});

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
            'Asystent planowania urlopów',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _AssistantInfoRow(
            ikona: Icons.check_circle_outline,
            tytul: 'Sugestia',
            opis:
            'Najkorzystniejszy termin dla wybranej osoby: 17.08.2026 - 21.08.2026.',
          ),
          const SizedBox(height: 10),
          _AssistantInfoRow(
            ikona: Icons.warning_amber_rounded,
            tytul: 'Ostrzeżenie',
            opis:
            'W terminie 01.09.2026 - 07.09.2026 zespół może zejść poniżej minimalnej obsady.',
          ),
          const SizedBox(height: 10),
          _AssistantInfoRow(
            ikona: Icons.event_busy_outlined,
            tytul: 'Kolizja',
            opis:
            'W wybranym okresie są już przypisane zadania i wydarzenia dla tej osoby.',
          ),
        ],
      ),
    );
  }
}

class _AssistantInfoRow extends StatelessWidget {
  const _AssistantInfoRow({
    required this.ikona,
    required this.tytul,
    required this.opis,
  });

  final IconData ikona;
  final String tytul;
  final String opis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikona, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tytul,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}