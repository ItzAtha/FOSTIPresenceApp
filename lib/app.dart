import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/core/theme/dark_mode.dart';
import 'package:attendance_management/core/theme/light_mode.dart';
import 'package:attendance_management/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.savedThemeData});

  final AdaptiveThemeMode? savedThemeData;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: const ToastificationConfig(maxToastLimit: 1),
      child: AdaptiveTheme(
        debugShowFloatingThemeButton: true,
        light: LightMode.initialize(),
        dark: DarkMode.initialize(),
        initial: widget.savedThemeData ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Presence Management',
            localizationsDelegates: [
              ...context.localizationDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: theme,
            darkTheme: darkTheme,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}
