import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../announcements/domain/models/announcement.dart';
import '../../../announcements/presentation/providers/announcements_providers.dart';

class DashboardAnnouncementsPanel extends ConsumerWidget {
  const DashboardAnnouncementsPanel({
    super.key,
    required this.onOpenAnnouncement,
  });

  final void Function(Announcement announcement) onOpenAnnouncement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnnouncements = ref.watch(announcementsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncAnnouncements.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 240,
            child: Center(
              child: Text('Błąd dashboardu komunikatów: $error'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox(
                height: 240,
                child: Center(
                  child: Text('Brak aktywnych komunikatów.'),
                ),
              );
            }

            final formatter = DateFormat('dd.MM.yyyy HH:mm');
            final visibleItems = items.take(12).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Komunikaty',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final item in visibleItems) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOpenAnnouncement(item),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatter.format(item.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}