import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location == '/' || location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/my-calendar')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/attendance')) return 3;
    if (location.startsWith('/personnel')) return 4;
    if (location.startsWith('/leave')) return 5;
    if (location.startsWith('/tasks')) return 6;
    if (location.startsWith('/announcements')) return 7;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isExtended = MediaQuery.of(context).size.width >= 1280;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 78,
            minExtendedWidth: 240,
            extended: isExtended,
            selectedIndex: selectedIndex,
            useIndicator: true,
            labelType: isExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/my-calendar');
                  break;
                case 2:
                  context.go('/calendar');
                  break;
                case 3:
                  context.go('/attendance');
                  break;
                case 4:
                  context.go('/personnel');
                  break;
                case 5:
                  context.go('/leave');
                  break;
                case 6:
                  context.go('/tasks');
                  break;
                case 7:
                  context.go('/announcements');
                  break;
              }
            },
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  const Icon(Icons.flight, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ESKADRA',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Mój kalendarz'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Kalendarz wspólny'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Obecności'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Personel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.beach_access_outlined),
                selectedIcon: Icon(Icons.beach_access),
                label: Text('Urlopy'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Zadania'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.campaign_outlined,
                  color: Colors.redAccent,
                ),
                selectedIcon: Icon(
                  Icons.campaign,
                  color: Colors.redAccent,
                ),
                label: Text('Komunikaty'),
              ),
            ],
            trailing: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Ustawienia',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.logout_outlined),
                      tooltip: 'Wyloguj',
                    ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
