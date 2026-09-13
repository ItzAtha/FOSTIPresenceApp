import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/manager/bluetooth_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../../translations/locale_keys.g.dart';
import '../../../core/app_constants.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<StatefulWidget> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool isScanning = true;
  late BluetoothManager btManager;

  Future<void> initializeBluetooth() async {
    setState(() => isScanning = true);

    btManager.initialize().then((isSuccess) {
      if (!mounted) return;

      if (isSuccess) {
        setState(() => isScanning = false);

        Toastification().show(
          context: context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_success_discover.tr(context: context),
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
        print('Bluetooth initialization success');
      } else {
        Toastification().show(
          context: context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_fail_discover.tr(context: context),
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
        print('Bluetooth initialization failed');
      }
    });
  }

  @override
  void initState() {
    super.initState();

    btManager = BluetoothManager(context: context);
    initializeBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: isScanning
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ValueListenableBuilder(
                      valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                      builder: (_, mode, child) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mode == AdaptiveThemeMode.light
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Text(LocaleKeys.bluetooth_page_loading_data_process.tr(context: context)),
                  ],
                ),
              )
            : BluetoothManager.getDevicesList.isNotEmpty
            ? RefreshIndicator(
                onRefresh: initializeBluetooth,
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: BluetoothManager.getDevicesList.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = BluetoothManager.getDevicesList[index];

                    return ValueListenableBuilder<Map<BluetoothDevice, BTConnectionState>>(
                      valueListenable: BluetoothManager.getDeviceStatus,
                      builder: (context, value, _) {
                        return ListTile(
                          title: Text(
                            device.platformName.isEmpty
                                ? LocaleKeys.bluetooth_page_unknown_device.tr(context: context)
                                : device.platformName,
                          ),
                          subtitle: Text(device.remoteId.str),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    (value[device] != BTConnectionState.connecting &&
                                        value[device] != BTConnectionState.disconnecting)
                                    ? () async {
                                        if (!device.isConnected) {
                                          if (BluetoothManager.isBluetoothConnected) {
                                            Toastification().show(
                                              context: context,
                                              title: Text(
                                                LocaleKeys.alert_notify_bluetooth_title.tr(
                                                  context: context,
                                                ),
                                              ),
                                              description: Text(
                                                LocaleKeys
                                                    .alert_notify_bluetooth_description_already_connected
                                                    .tr(context: context),
                                              ),
                                              type: ToastificationType.warning,
                                              style: ToastificationStyle.flat,
                                              alignment: Alignment.bottomCenter,
                                              autoCloseDuration: const Duration(seconds: 2),
                                              animationDuration: const Duration(milliseconds: 500),
                                            );
                                            return;
                                          }

                                          setState(
                                            () => value[device] = BTConnectionState.connecting,
                                          );

                                          bool isSuccess = await btManager.connectToDevice(device);
                                          if (isSuccess) {
                                            setState(
                                              () => value[device] = BTConnectionState.connected,
                                            );
                                            if (!context.mounted) return;

                                            Toastification().show(
                                              context: context,
                                              title: Text(
                                                LocaleKeys.alert_notify_bluetooth_title.tr(
                                                  context: context,
                                                ),
                                              ),
                                              description: Text(
                                                LocaleKeys
                                                    .alert_notify_bluetooth_description_bt_success_connect
                                                    .tr(
                                                      context: context,
                                                      namedArgs: {
                                                        'device': device.platformName.isEmpty
                                                            ? LocaleKeys
                                                                  .bluetooth_page_unknown_device
                                                                  .tr(context: context)
                                                            : device.platformName,
                                                      },
                                                    ),
                                              ),
                                              type: ToastificationType.success,
                                              style: ToastificationStyle.flat,
                                              alignment: Alignment.bottomCenter,
                                              autoCloseDuration: const Duration(seconds: 2),
                                              animationDuration: const Duration(milliseconds: 500),
                                            );
                                          } else {
                                            setState(
                                              () => value[device] = BTConnectionState.disconnected,
                                            );
                                            if (!context.mounted) return;

                                            Toastification().show(
                                              context: context,
                                              title: Text(
                                                LocaleKeys.alert_notify_bluetooth_title.tr(
                                                  context: context,
                                                ),
                                              ),
                                              description: Text(
                                                LocaleKeys
                                                    .alert_notify_bluetooth_description_bt_fail_connect
                                                    .tr(
                                                      context: context,
                                                      namedArgs: {
                                                        'device': device.platformName.isEmpty
                                                            ? LocaleKeys
                                                                  .bluetooth_page_unknown_device
                                                                  .tr(context: context)
                                                            : device.platformName,
                                                      },
                                                    ),
                                              ),
                                              type: ToastificationType.error,
                                              style: ToastificationStyle.flat,
                                              alignment: Alignment.bottomCenter,
                                              autoCloseDuration: const Duration(seconds: 2),
                                              animationDuration: const Duration(milliseconds: 500),
                                            );
                                          }
                                        } else {
                                          try {
                                            setState(
                                              () => value[device] = BTConnectionState.disconnecting,
                                            );
                                            await btManager.disconnectFromDevice(device);
                                            setState(
                                              () => value[device] = BTConnectionState.disconnected,
                                            );
                                          } catch (e) {
                                            print('Disconnection failed: $e');
                                          }
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(120.0, 40.0),
                                ),
                                child: switch (value[device]) {
                                  BTConnectionState.connected => Text(
                                    "Disconnect",
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  BTConnectionState.disconnected => Text(
                                    "Connect",
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  BTConnectionState.connecting ||
                                  BTConnectionState.disconnecting => SizedBox(
                                    width: 16.0,
                                    height: 16.0,
                                    child: ValueListenableBuilder(
                                      valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                                      builder: (_, mode, child) {
                                        return CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            mode == AdaptiveThemeMode.light
                                                ? AppColors.secondary
                                                : AppColors.secondary.withValues(alpha: 0.6),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  _ => Text(
                                    "Unknown",
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: initializeBluetooth,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            LocaleKeys.bluetooth_page_loading_data_no_device.tr(context: context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
