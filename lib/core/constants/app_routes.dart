class AppRoutes {
  AppRoutes._();

  // ============[ Navigation route ]============
  static const String homeRoutePath = '/home';
  static const String memberRoutePath = '/members';
  static const String eventRoutePath = '/events';
  static const String settingRoutePath = '/setting';

  // ============[ Setting & Legality route ]============
  static const String faqRoutePath = 'faq';
  static const String privacyPolicyRoutePath = 'privacy-policy';
  static const String termsOfServiceRoutePath = 'terms-of-service';

  // ============[ Action button routes ]============
  static const String registerRoutePath = 'register';
  static const String memberExcelRoutePath = 'excel';
  static const String memberExcelViewRoutePath = ':title';
  static const String bluetoothRoutePath = 'bluetooth';
  static const String attendanceRoutePath = 'attendance';
  static const String attendanceModeRoutePath = ':attendanceMode';
}
