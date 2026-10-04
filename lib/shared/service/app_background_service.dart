import 'dart:ui';

import 'package:attendance_management/core/app_constants.dart';
import 'package:attendance_management/shared/service/ble_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class AppBackgroundService {
  static const String channelId = 'foreground_service_channel';
  static const int systemNotificationId = 888;
  static const int notificationId = 999;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    final localNotificationPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
      channelId,
      "Background Service Monitor",
      description: "Channel to monitor status in the background.",
      importance: Importance.max,
    );

    await localNotificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: channelId,
        foregroundServiceNotificationId: systemNotificationId,
        initialNotificationTitle: "Background Service is active!",
        initialNotificationContent: "Waiting for receive data....",
        foregroundServiceTypes: [
          AndroidForegroundType.dataSync,
          AndroidForegroundType.connectedDevice,
        ],
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final localNotification = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    await localNotification.initialize(
      settings: const InitializationSettings(android: initializationSettings),
    );

    bool isAppInForeground = true;

    service.on('app_lifecycle_state_changed').listen((data) {
      if (data != null) {
        isAppInForeground = (data['lifecycle_state'] == AppLifecycleState.resumed.name);

        if (kDebugMode) {
          debugPrint(
            "User position status updated: ${isAppInForeground ? 'Inside App' : 'Outside App'}",
          );
        }
      }
    });

    service
        .on('ble_connection_state_changed')
        .listen(
          (data) async {
            if (data == null) return;

            String bleName = "Unknown";
            String bleDescription = "";
            BleConnectionState bleState = BleConnectionState.disconnected;

            try {
              bleName = data['ble_name'];
              bleState = BleConnectionState.values.byName(data['ble_state']);
            } catch (_, trace) {
              if (kDebugMode) {
                debugPrintStack(stackTrace: trace, label: "Error occurred while parsing BLE data");
              }
            }

            if (bleState == BleConnectionState.reconnected) {
              bleDescription =
                  "The Bluetooth device connection with name $bleName has been reconnected.";
            } else if (bleState == BleConnectionState.disconnected) {
              bleDescription = "The Bluetooth device connection with name $bleName has been lost.";
            }

            if (!isAppInForeground) {
              await localNotification.show(
                id: notificationId,
                title: "Bluetooth Device",
                body: bleDescription,
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    channelId,
                    "Background Monitor Service",
                    channelDescription: "Notification for background monitor service",
                    importance: Importance.max,
                    priority: Priority.high,
                    ongoing: true,
                  ),
                ),
                payload: AppRoutes.bluetoothMenuRoute.name,
              );
              return;
            }

            service.invoke('ble_toast_callback', {'message': bleDescription});
          },
          onError: (_, trace) {
            if (kDebugMode) {
              debugPrintStack(
                stackTrace: trace,
                label: "Error occurred while processing BLE connection state",
              );
            }
          },
        );
  }
}
