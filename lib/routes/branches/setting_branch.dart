part of '../app_router.dart';

class SettingBranchData extends StatefulShellBranchData {
  const SettingBranchData();
}

class SettingRoute extends GoRouteData with $SettingRoute {
  const SettingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SettingPage();
}

class FaqRoute extends GoRouteData with $FaqRoute {
  const FaqRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const FrequentlyAskQuestionPage();
}

class PrivacyPolicyRoute extends GoRouteData with $PrivacyPolicyRoute {
  const PrivacyPolicyRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const PrivacyPolicyPage();
}

class TermsOfServiceRoute extends GoRouteData with $TermsOfServiceRoute {
  const TermsOfServiceRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppRouter.rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const TermsOfServicePage();
}