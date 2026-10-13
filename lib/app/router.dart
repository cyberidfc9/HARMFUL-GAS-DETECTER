import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/sensor_detail/presentation/sensor_detail_screen.dart';
import '../features/device_status/presentation/device_status_screen.dart';
import '../data/models/sensor_reading.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Overview
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // Branch 2: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),

        // Branch 3: Alerts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),

        // Branch 4: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Sub-screens pushed onto root navigator
    GoRoute(
      path: '/sensor/:type',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final typeStr = state.pathParameters['type'] ?? 'mq2';
        final sensorType = SensorType.fromKey(typeStr);
        return SensorDetailScreen(sensorType: sensorType);
      },
    ),
    GoRoute(
      path: '/device-status',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DeviceStatusScreen(),
    ),
  ],
);
