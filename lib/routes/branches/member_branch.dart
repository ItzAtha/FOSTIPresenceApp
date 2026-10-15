part of '../app_router.dart';

class MemberBranchData extends StatefulShellBranchData {
  const MemberBranchData();
}

class MemberRoute extends GoRouteData with $MemberRoute {
  const MemberRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MemberPage();
}

class AddMemberRoute extends GoRouteData with $AddMemberRoute {
  const AddMemberRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const RegisterPage();
}

class MemberExcelRoute extends GoRouteData with $MemberExcelRoute {
  const MemberExcelRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const MembersExcelPage();
}

class MemberExcelViewRoute extends GoRouteData with $MemberExcelViewRoute {
  const MemberExcelViewRoute({
    required this.title,
    required this.$extra,
  });

  final String title;
  final Map<String, List<List<String>>> $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MembersExcelViewerPage(title: title, excelData: $extra);
  }
}