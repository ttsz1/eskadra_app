import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/announcement.dart';
import '../providers/announcements_providers.dart';
import '../widgets/add_announcement_dialog.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({
    super.key,
    this.focusAnnouncementId,
  });

  final String? focusAnnouncementId;

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  Announcement? _selected;

  @override
  Widget build(BuildContext context) {
    final asyncAnnouncements = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunikaty'),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: () {
              ref.read(announcementsActionsProvider).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const AddAnnouncementDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dodaj komunikat'),
            ),
          ),
        ],
      ),
      body: asyncAnnouncements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Błąd ładowania komunikatów: $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Brak aktywnych komunikatów.'),
            );
          }

          _selected ??= _resolveInitialSelection(items);

          return Row(
            children: [
              SizedBox(
                width: 420,
                child: _AnnouncementsList(
                  items: items,
                  selectedId: _selected?.id,
                  onSelect: (item) {
                    setState(() => _selected = item);
                  },
                  onDelete: (item) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usuń komunikat'),
                        content: Text(
                          'Czy na pewno usunąć komunikat "${item.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Anuluj'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true || !mounted) return;

                    try {
                      await ref
                          .read(announcementsActionsProvider)
                          .deleteAnnouncement(item.id);

                      if (!mounted) return;

                      final remaining =
                      items.where((element) => element.id != item.id).toList();

                      setState(() {
                        _selected = remaining.isEmpty ? null : remaining.first;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Komunikat usunięty.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Nie udało się usunąć: $e')),
                      );
                    }
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _selected == null
                    ? const Center(
                  child: Text('Wybierz komunikat z listy.'),
                )
                    : _AnnouncementDetails(item: _selected!),
              ),
            ],
          );
        },
      ),
    );
  }

  Announcement? _resolveInitialSelection(List<Announcement> items) {
    final focusId = widget.focusAnnouncementId;
    if (focusId != null) {
      for (final item in items) {
        if (item.id == focusId) return item;
      }
    }
    return items.isEmpty ? null : items.first;
  }
}

class _AnnouncementsList extends StatelessWidget {
  const _AnnouncementsList({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
  });

  final List<Announcement> items;
  final String? selectedId;
  final ValueChanged<Announcement> onSelect;
  final ValueChanged<Announcement> onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = item.id == selectedId;

        return Material(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dodano: ${formatter.format(item.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Usuń',
                    onPressed: () => onDelete(item),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnnouncementDetails extends StatelessWidget {
  const _AnnouncementDetails({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetaChip(
                    icon: Icons.person_outline_rounded,
                    label: 'Dodał: ${item.authorName}',
                  ),
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: 'Dodano: ${formatter.format(item.createdAt)}',
                  ),
                  if (item.autoDeleteAt != null)
                    _MetaChip(
                      icon: Icons.auto_delete_rounded,
                      label:
                      'Auto delete: ${formatter.format(item.autoDeleteAt!)}',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SelectableText(
                item.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}