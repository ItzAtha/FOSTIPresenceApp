import 'package:attendance_management/core/app_constants.dart';
import 'package:attendance_management/features/dashboard/views/events_page.dart';
import 'package:attendance_management/features/dashboard/views/members_page.dart';
import 'package:attendance_management/features/dashboard/views/register_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/dashboard/base_pages.dart';
import '../features/dashboard/views/bluetooth_page.dart';
import '../features/dashboard/views/home_page.dart';
import '../features/dashboard/views/settings_page.dart';

class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    observers: [routeObserver],
    navigatorKey: _navigatorKey,
    initialLocation: AppRoutes.homeRoute.path,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BasePages(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.homeRoute.name,
                path: AppRoutes.homeRoute.path,
                builder: (context, state) => const HomePage(),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: _navigatorKey,
                    name: AppRoutes.bluetoothMenuRoute.name,
                    path: AppRoutes.bluetoothMenuRoute.path,
                    builder: (context, state) => const BluetoothPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.memberRoute.name,
                path: AppRoutes.memberRoute.path,
                builder: (context, state) => const MemberPage(),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: _navigatorKey,
                    name: AppRoutes.addMemberRoute.name,
                    path: AppRoutes.addMemberRoute.path,
                    builder: (context, state) => const RegisterPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.eventRoute.name,
                path: AppRoutes.eventRoute.path,
                builder: (context, state) => const EventPage(),
                routes: <RouteBase>[
                  // GoRoute(
                  //   name: AppRoutes.addEventRoute.name,
                  //   path: AppRoutes.addEventRoute.path,
                  //   builder: (context, state) => const AddEventPage(),
                  // ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.settingRoute.name,
                path: AppRoutes.settingRoute.path,
                builder: (context, state) => const SettingPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
