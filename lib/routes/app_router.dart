import 'package:attendance_management/core/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/dashboard_pages_views.dart';

part 'app_router.g.dart';
part 'branches/event_branch.dart';
part 'branches/home_branch.dart';
part 'branches/member_branch.dart';
part 'branches/setting_branch.dart';

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    // ===================[ BRANCH 1: HOME ]===================
    TypedStatefulShellBranch<HomeBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<HomeRoute>(
          path: AppRoutes.homeRoutePath,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<BluetoothMenuRoute>(path: AppRoutes.bluetoothRoutePath),
            TypedGoRoute<MemberAttendanceRoute>(
              path: AppRoutes.attendanceRoutePath,
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<MemberAttendanceModeRoute>(path: AppRoutes.attendanceModeRoutePath),
              ],
            ),
          ],
        ),
      ],
    ),

    // ===================[ BRANCH 2: MEMBER ]===================
    TypedStatefulShellBranch<MemberBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MemberRoute>(
          path: AppRoutes.memberRoutePath,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<AddMemberRoute>(path: AppRoutes.registerRoutePath),
            TypedGoRoute<MemberExcelRoute>(
              path: AppRoutes.memberExcelRoutePath,
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<MemberExcelViewRoute>(path: AppRoutes.memberExcelViewRoutePath),
              ],
            ),
          ],
        ),
      ],
    ),

    // ===================[ BRANCH 3: EVENT ]===================
    TypedStatefulShellBranch<EventBranchData>(
      routes: <TypedRoute<RouteData>>[TypedGoRoute<EventRoute>(path: AppRoutes.eventRoutePath)],
    ),

    // ===================[ BRANCH 4: SETTINGS ]===================
    TypedStatefulShellBranch<SettingBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingRoute>(
          path: AppRoutes.settingRoutePath,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<FaqRoute>(path: AppRoutes.faqRoutePath),
            TypedGoRoute<PrivacyPolicyRoute>(path: AppRoutes.privacyPolicyRoutePath),
            TypedGoRoute<TermsOfServiceRoute>(path: AppRoutes.termsOfServiceRoutePath),
          ],
        ),
      ],
    ),
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return BasePages(navigationShell: navigationShell);
  }
}

class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    observers: [routeObserver],
    navigatorKey: rootNavigatorKey,
    initialLocation: const HomeRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
  );
}
