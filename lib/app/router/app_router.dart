import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/leave/presentation/screens/leave_screen.dart';
import '../../features/my_calendar/presentation/screens/my_calendar_screen.dart';
import '../../features/obecnosci/presentation/screens/obecnosci_screen.dart';
import '../../features/personnel/presentation/screens/personnel_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../shared/navigation/app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: SupabaseAuthRefreshNotifier(),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnLogin) {
      return '/login';
    }

    if (isLoggedIn && isOnLogin) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          redirect: (context, state) => '/',
        ),
        GoRoute(
          path: '/my-calendar',
          name: 'my-calendar',
          builder: (context, state) => const MyCalendarScreen(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/attendance',
          name: 'attendance',
          builder: (context, state) => const ObecnosciScreen(),
        ),
        GoRoute(
          path: '/personnel',
          name: 'personnel',
          builder: (context, state) => const PersonnelScreen(),
        ),
        GoRoute(
          path: '/leave',
          name: 'leave',
          builder: (context, state) => const LeaveScreen(),
        ),
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/announcements',
          name: 'announcements',
          builder: (context, state) {
            final focusId = state.uri.queryParameters['focus'];
            return AnnouncementsScreen(
              focusAnnouncementId: focusId,
            );
          },
        ),
        GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) => const ChatListScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Text(
          'Nie znaleziono strony: ${state.uri}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  },
);

class SupabaseAuthRefreshNotifier extends ChangeNotifier {
  SupabaseAuthRefreshNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}