import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:attendance_management/core/app_constants.dart';
import 'package:attendance_management/shared/service/ble_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

@pragma('vm:entry-point')
class AppBackgroundService {
  static const String channelId = 'foreground_service_channel';
  static const int bleNotificationId = 111;
  static const int simNotificationId = 222;
  static const int systemNotificationId = 999;

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
      iosConfiguration: IosConfiguration(onForeground: onStart, onBackground: onIosBackground),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    final localNotification = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    await localNotification.initialize(
      settings: const InitializationSettings(android: initializationSettings),
    );

    final prefsOption = const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
        fileName: 'settings_data',
      ),
    );

    final settingPrefs = SharedPreferencesAsync(options: prefsOption);

    bool isAppInForeground = true;

    service.on('app_lifecycle_state_changed').listen((data) {
      if (data != null) {
        isAppInForeground = (data['lifecycle_state'] == AppLifecycleState.resumed.name);

        if (kDebugMode) {
          debugPrint(
            "[Background Service] User position status updated: ${isAppInForeground ? 'Inside App' : 'Outside App'}",
          );
        }
      }
    });

    service
        .on('ble_connection_state_changed')
        .listen(
          (data) async {
            if (data == null) return;

            if (kDebugMode) {
              debugPrint("[Background Service] Received ble connection state data: $data");
            }

            String bleName = data['ble_name'] ?? "Unknown";
            String bleDescription = "";
            BleConnectionState? bleState;

            try {
              bleState = BleConnectionState.values.byName(data['ble_state']);
            } catch (_, trace) {
              if (kDebugMode) {
                debugPrintStack(
                  stackTrace: trace,
                  label: "[Background Service] Error occurred while parsing BLE state",
                );
              }
            }

            if (bleState != null) {
              if (bleState == BleConnectionState.reconnected) {
                bleDescription =
                    "The Bluetooth device connection with name $bleName has been reconnected.";
              } else if (bleState == BleConnectionState.disconnected) {
                bleDescription =
                    "The Bluetooth device connection with name $bleName has been lost.";
              }
            } else {
              bleDescription =
                  "The Bluetooth device connection with name $bleName is in an unknown state.";
            }

            if (!isAppInForeground) {
              await localNotification.show(
                id: bleNotificationId,
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
                label: "[Background Service] Error occurred while processing BLE connection state",
              );
            }
          },
        );

    service.on('system_data_received').listen((data) async {
      if (data == null) return;

      if (kDebugMode) {
        debugPrint("[Background Service] Received system data: $data");
      }

      Map<String, dynamic> decodedData = {};
      try {
        decodedData = jsonDecode(data['data']) as Map<String, dynamic>;
      } catch (_, trace) {
        if (kDebugMode) {
          debugPrintStack(
            stackTrace: trace,
            label: "[Background Service] Error occurred while decoding system data",
          );
        }
      }

      if (decodedData.isNotEmpty) {
        try {
          if (decodedData['type'] == "SIM_QUOTA_DETAILS") {
            String simData = jsonEncode(decodedData['data'] as Map<String, dynamic>);
            if (await settingPrefs.containsKey('sim_quota_data')) {
              String? currentSimData = await settingPrefs.getString('sim_quota_data');
              if (currentSimData != null) {
                bool isDataChange = simData.compareTo(currentSimData) != 0;
                if (isDataChange) {
                  settingPrefs.setString('sim_quota_data', simData);
                }
              }
            } else {
              settingPrefs.setString('sim_quota_data', simData);
            }

            if (kDebugMode) {
              debugPrint("[Background Service] SIM data: $simData");
            }
          }
        } catch (_, trace) {
          if (kDebugMode) {
            debugPrintStack(
              stackTrace: trace,
              label: "[Background Service] Error occurred while processing system data",
            );
          }
        }
      }
    });

    Timer.periodic(const Duration(hours: 6), (timer) async {
      if (kDebugMode) {
        debugPrint("[Background Service] Checking SIM quota expired date....");
      }

      if (await settingPrefs.containsKey('sim_quota_data')) {
        String? simData = await settingPrefs.getString('sim_quota_data');
        if (simData != null) {
          Map<String, dynamic> decodedSimData = jsonDecode(simData);
          DateTime? expiredQuota;

          try {
            String rawExpiredDate = decodedSimData['expiredDateTime'].toString().replaceAll(
              '/',
              '-',
            );
            final formattedExpiredDate = DateFormat("yyyy-MM-dd HH:mm:ss");
            expiredQuota = formattedExpiredDate.parse(rawExpiredDate);
          } catch (_, stackTrace) {
            if (kDebugMode) {
              debugPrintStack(
                stackTrace: stackTrace,
                label: "[Background Service] Error occurred while parsing expired date",
              );
            }
          }

          if (expiredQuota != null) {
            Set<int> notifyDay = {15, 10, 5, 3, 2, 1};
            DateTime currentDate = DateTime.now();

            // Calculate the number of days remaining until the SIM quota expires
            final start = DateTime(currentDate.year, currentDate.month, currentDate.day);
            final end = DateTime(expiredQuota.year, expiredQuota.month, expiredQuota.day);

            final daysRemaining = end.difference(start).inDays;

            String simDescription = "";
            if (currentDate.isAfter(expiredQuota)) {
              simDescription = "SIM quota has expired. Please top up the SIM card's data allowance so the ESP32 modem can reconnect to the internet.";

              if (kDebugMode) {
                debugPrint("[Background Service] SIM quota has expired!");
              }
            } else if (notifyDay.contains(daysRemaining)) {
              simDescription = "SIM quota is about to be expired in $daysRemaining day(s).";

              if (kDebugMode) {
                debugPrint("[Background Service] Quota expires in $daysRemaining day(s)");
              }
            }

            if (!isAppInForeground) {
              await localNotification.show(
                id: simNotificationId,
                title: "SIM Quota",
                body: simDescription,
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
              );
              return;
            }

            service.invoke('sim_toast_callback', {'message': simDescription});
          }
        }
      }
    });
  }
}
