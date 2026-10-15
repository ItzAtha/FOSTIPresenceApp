part of '../app_router.dart';

class EventBranchData extends StatefulShellBranchData {
  const EventBranchData();
}

class EventRoute extends GoRouteData with $EventRoute {
  const EventRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const EventPage();
}