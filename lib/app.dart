import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/records/records_page.dart';
import 'pages/timer/timer_page.dart';
import 'pages/stats/stats_page.dart';
import 'pages/settings/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/records',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                builder: (context, state) => const RecordsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                builder: (context, state) => const TimerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class StudyRecorderApp extends ConsumerWidget {
  const StudyRecorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: '学习记录器',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4FC3F7),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: '记录'),
          NavigationDestination(icon: Icon(Icons.timer), label: '计时'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '统计'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
