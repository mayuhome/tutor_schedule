import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/students/presentation/student_list_screen.dart';
import '../../features/students/presentation/student_detail_screen.dart';
import '../../features/students/presentation/student_form_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/schedule/presentation/schedule_form_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/app_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/students',
              builder: (context, state) => const StudentListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const StudentFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => StudentDetailScreen(
                    studentId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => StudentFormScreen(
                        studentId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const ScheduleFormScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) => ScheduleFormScreen(
                    scheduleId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
