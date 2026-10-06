import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/core/theme/dark_mode.dart';
import 'package:attendance_management/core/theme/light_mode.dart';
import 'package:attendance_management/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.savedThemeData});

  final AdaptiveThemeMode? savedThemeData;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  StreamSubscription? bleToastSubscription;
  StreamSubscription? simToastSubscription;
  final FlutterBackgroundService backgroundService = FlutterBackgroundService();

  Future<void> initUiNotificationReceiver() async {
    final localNotification = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    await localNotification.initialize(
      settings: const InitializationSettings(android: initializationSettings),
      onDidReceiveNotificationResponse: (response) {
        final routeName = response.payload;

        if (routeName != null) {
          AppRouter.router.pushNamed(routeName);

          if (kDebugMode) {
            debugPrint("Received route data from notification: ${response.payload}");
          }
        } else {
          if (kDebugMode) {
            debugPrint("Error occurred while navigating to route.");
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    initUiNotificationReceiver();

    backgroundService.invoke('app_lifecycle_state_changed', {
      'lifecycle_state': AppLifecycleState.resumed.name,
    });

    bleToastSubscription = backgroundService.on('ble_toast_callback').listen((data) {
      if (data != null) {
        Toastification().show(
          title: const Text("Bluetooth Device"),
          description: Text(data['message']),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      }
    });

    simToastSubscription = backgroundService.on('sim_toast_callback').listen((data) {
      if (data != null) {
        Toastification().show(
          title: const Text("SIM Quota"),
          description: Text(data['message']),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      backgroundService.invoke('app_lifecycle_state_changed', {
        'lifecycle_state': AppLifecycleState.resumed.name,
      });
    } else if (state == AppLifecycleState.paused) {
      backgroundService.invoke('app_lifecycle_state_changed', {
        'lifecycle_state': AppLifecycleState.paused.name,
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    bleToastSubscription?.cancel();
    simToastSubscription?.cancel();
    super.dispose();
  }

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
            title: 'Attendance Management',
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
