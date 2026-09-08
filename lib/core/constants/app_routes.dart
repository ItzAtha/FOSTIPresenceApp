class AppRoutes {
  AppRoutes._();

  // ============[ Navigation route ]============
  static const ({String name, String path}) homeRoute = (path: '/home', name: "home");
  static const ({String name, String path}) memberRoute = (path: '/members', name: "members");
  static const ({String name, String path}) eventRoute = (path: '/events', name: "events");
  static const ({String name, String path}) settingRoute = (path: '/setting', name: "settings");

  // ============[ Action button routes ]============
  static const ({String name, String path}) addMemberRoute = (path: 'add-member', name: "add-member");
  static const ({String name, String path}) bluetoothMenuRoute = (path: 'bluetooth-menu', name: "bluetooth-menu");
  static const ({String name, String path}) memberAttendanceRoute = (path: 'member-presence', name: "member-presence");
}
