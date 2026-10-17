import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_constants.dart' show AppSizes, AppColors;
import '../../../core/translations/locale_keys.g.dart';
import '../../../shared/service/ble_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<StatefulWidget> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool isScanning = true;
  bool isOtherBTAlreadyConnecting = false;
  late BleService bleService;

  Future<void> initializeBluetooth() async {
    setState(() => isScanning = true);

    bleService
        .requestPermissions()
        .then((value) async {
          final status = value.status;
          final permission = value.permission;

          switch (status) {
            case BlePermissionStatus.request_success:
              final bleStatus = await bleService.startScanning();

              if (!mounted) return;

              if (bleStatus == BleStatus.scanning_success) {
                Toastification().show(
                  title: Text(LocaleKeys.notification_bluetooth_title.tr(context: context)),
                  description: Text(
                    LocaleKeys.notification_bluetooth_description_discover_success.tr(
                      context: context,
                    ),
                  ),
                  type: ToastificationType.info,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );
              } else if (bleStatus == BleStatus.ble_stream_sub_error) {
                Toastification().show(
                  title: Text(LocaleKeys.notification_bluetooth_title.tr(context: context)),
                  description: Text(
                    LocaleKeys.notification_bluetooth_description_discover_failed.tr(
                      context: context,
                    ),
                  ),
                  type: ToastificationType.info,
                  style: ToastificationStyle.flat,
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: const Duration(milliseconds: 500),
                );
              }
              break;
            case BlePermissionStatus.request_failed:
              if (!mounted) return;

              Toastification().show(
                title: Text(
                  LocaleKeys.notification_bluetooth_permission_title.tr(context: context),
                ),
                description: Text(
                  LocaleKeys.notification_bluetooth_permission_description_request_failed.tr(
                    context: context,
                  ),
                ),
                type: ToastificationType.info,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );
              break;
            case BlePermissionStatus.request_denied:
              if (!mounted) return;

              Toastification().show(
                title: Text(
                  LocaleKeys.notification_bluetooth_permission_title.tr(context: context),
                ),
                description: Text(
                  LocaleKeys.notification_bluetooth_permission_description_not_granted.tr(
                    context: context,
                    namedArgs: {'permission': permission.toString()},
                  ),
                ),
                type: ToastificationType.info,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );
              break;
            case BlePermissionStatus.not_support:
              if (!mounted) return;

              Toastification().show(
                title: Text(
                  LocaleKeys.notification_bluetooth_permission_title.tr(context: context),
                ),
                description: Text(
                  LocaleKeys.notification_bluetooth_permission_description_not_support.tr(
                    context: context,
                  ),
                ),
                type: ToastificationType.info,
                style: ToastificationStyle.flat,
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                animationDuration: const Duration(milliseconds: 500),
              );
              break;
          }
        })
        .whenComplete(() {
          if (mounted) {
            setState(() => isScanning = false);
          }
        });
  }

  @override
  void initState() {
    super.initState();

    bleService = BleService();
    initializeBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            RefreshIndicator(
              onRefresh: initializeBluetooth,
              color: AppColors.primary,
              child: ValueListenableBuilder<Map<BluetoothDevice, BleConnectionState>>(
                valueListenable: bleService.foundDevicesList,
                builder: (context, devices, _) {
                  if (isScanning && devices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ValueListenableBuilder(
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
                          const SizedBox(height: 16.0),
                          Text(LocaleKeys.bluetooth_page_data_state_loading.tr(context: context)),
                        ],
                      ),
                    );
                  }

                  if (devices.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Text(
                                LocaleKeys.bluetooth_page_data_state_no_device.tr(context: context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  final devicesList = devices.entries.toList()
                    ..sort((a, b) {
                      String nameA = bleService.getDeviceName(a.key);
                      String nameB = bleService.getDeviceName(b.key);
                      return nameB.compareTo(nameA);
                    });

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index].key;
                      final state = devicesList[index].value;
                      final deviceName = bleService.getDeviceName(device);
                      final unknownDevice = LocaleKeys.bluetooth_page_unknown_device.tr(
                        context: context,
                      );

                      return ListTile(
                        title: Text(deviceName.isNotEmpty ? deviceName : unknownDevice),
                        subtitle: Text("${device.remoteId}"),
                        trailing: switch (state) {
                          BleConnectionState.connected => ElevatedButton(
                            onPressed: () async {
                              final status = await bleService.disconnectFromDevice();

                              if (!context.mounted) return;

                              if (status == BleConnectionStatus.success_disconnect) {
                                Toastification().show(
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_disconnect_success
                                        .tr(
                                          context: context,
                                          namedArgs: {
                                            'device': deviceName.isNotEmpty
                                                ? deviceName
                                                : unknownDevice,
                                          },
                                        ),
                                  ),
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flat,
                                  alignment: Alignment.bottomCenter,
                                  autoCloseDuration: const Duration(seconds: 2),
                                  animationDuration: const Duration(milliseconds: 500),
                                );
                              } else if (status == BleConnectionStatus.no_device_connected) {
                                Toastification().show(
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_already_disconnect
                                        .tr(context: context),
                                  ),
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flat,
                                  alignment: Alignment.bottomCenter,
                                  autoCloseDuration: const Duration(seconds: 2),
                                  animationDuration: const Duration(milliseconds: 500),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120.0, 40.0)),
                            child: Text(
                              LocaleKeys.bluetooth_state_disconnect.tr(context: context),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),

                          BleConnectionState.disconnected => ElevatedButton(
                            onPressed: () async {
                              if (bleService.isConnected) {
                                Toastification().show(
                                  context: context,
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_already_connected
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

                              if (isOtherBTAlreadyConnecting) {
                                Toastification().show(
                                  context: context,
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_already_connecting
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

                              isOtherBTAlreadyConnecting = true;
                              final status = await bleService.connectToDevice(device);
                              isOtherBTAlreadyConnecting = false;

                              if (!context.mounted) return;

                              if (status == BleConnectionStatus.success_connect) {
                                Toastification().show(
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_connect_success
                                        .tr(
                                          context: context,
                                          namedArgs: {
                                            'device': deviceName.isNotEmpty
                                                ? deviceName
                                                : unknownDevice,
                                          },
                                        ),
                                  ),
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flat,
                                  alignment: Alignment.bottomCenter,
                                  autoCloseDuration: const Duration(seconds: 2),
                                  animationDuration: const Duration(milliseconds: 500),
                                );
                              } else if (status == BleConnectionStatus.failed_connect) {
                                Toastification().show(
                                  title: Text(
                                    LocaleKeys.notification_bluetooth_title.tr(context: context),
                                  ),
                                  description: Text(
                                    LocaleKeys.notification_bluetooth_description_connect_failed.tr(
                                      context: context,
                                      namedArgs: {
                                        'device': deviceName.isNotEmpty
                                            ? deviceName
                                            : unknownDevice,
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
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120.0, 40.0)),
                            child: Text(
                              LocaleKeys.bluetooth_state_connect.tr(context: context),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),

                          BleConnectionState.connecting ||
                          BleConnectionState.disconnecting => ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120.0, 40.0)),
                            child: SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: ValueListenableBuilder(
                                valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
                                builder: (_, mode, child) {
                                  return CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      mode == AdaptiveThemeMode.light
                                          ? AppColors.secondary
                                          : AppColors.secondary.withValues(alpha: 0.6),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: BackButton(
                  onPressed: () {
                    context.pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
