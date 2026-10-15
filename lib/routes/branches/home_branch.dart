part of '../app_router.dart';

class HomeBranchData extends StatefulShellBranchData {
  const HomeBranchData();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

class BluetoothMenuRoute extends GoRouteData with $BluetoothMenuRoute {
  const BluetoothMenuRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const BluetoothPage();
}

class MemberAttendanceRoute extends GoRouteData with $MemberAttendanceRoute {
  const MemberAttendanceRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const PresenceMenuPage();
}

class MemberAttendanceModeRoute extends GoRouteData with $MemberAttendanceModeRoute {
  const MemberAttendanceModeRoute({required this.attendanceMode});

  final String attendanceMode;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PresenceModePage(attendanceMode: attendanceMode);
  }
}