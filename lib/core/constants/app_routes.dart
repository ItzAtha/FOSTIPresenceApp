class AppRoutes {
  AppRoutes._();

  // ============[ Navigation route ]============
  static const ({String name, String path}) homeRoute = (path: '/home', name: "home");
  static const ({String name, String path}) memberRoute = (path: '/members', name: "members");
  static const ({String name, String path}) eventRoute = (path: '/events', name: "events");
  static const ({String name, String path}) settingRoute = (path: '/setting', name: "settings");

  // ============[ Setting & Legality route ]============
  static const ({String name, String path}) faqRoute = (
    path: '/frequently-ask-question',
    name: "faq",
  );
  static const ({String name, String path}) privacyPolicyRoute = (
    path: 'privacy-policy',
    name: "privacy-policy",
  );
  static const ({String name, String path}) termsOfServiceRoute = (
    path: 'terms-of-service',
    name: "terms-of-service",
  );

  // ============[ Action button routes ]============
  static const ({String name, String path}) addMemberRoute = (
    path: 'add-member',
    name: "add-member",
  );
  static const ({String name, String path}) memberExcelRoute = (
  path: 'member-excel',
  name: "member-excel",
  );
  static const ({String name, String path}) bluetoothMenuRoute = (
    path: 'bluetooth-menu',
    name: "bluetooth-menu",
  );
  static const ({String name, String path}) memberAttendanceRoute = (
    path: 'member-presence',
    name: "member-presence",
  );
  static const ({String name, String path}) memberAttendanceModeRoute = (
    path: ':presenceMode',
    name: "member-presence-mode",
  );
}
