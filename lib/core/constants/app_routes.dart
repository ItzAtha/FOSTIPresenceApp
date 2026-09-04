class AppRoutes {
  AppRoutes._();

  // ============[ Navigation route ]============
  static const ({String name, String path}) homeRoute = (path: '/home', name: "home");
  static const ({String name, String path}) memberRoute = (path: '/members', name: "members");
  static const ({String name, String path}) eventRoute = (path: '/events', name: "events");
  static const ({String name, String path}) settingRoute = (path: '/setting', name: "settings");
}
