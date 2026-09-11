import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';

import '../translations/locale_keys.g.dart';

class BluetoothManager {
  final BuildContext _context;
  static final Queue<String> _receivedData = Queue<String>();

  final _serviceUUID = Guid(
    "3707a02f-16d0-4b0f-8465-540cf4f1e049",
  ); // Service char uuid of Bluetooth
  final _charUUIDWrite = Guid(
    "d62cc1aa-931c-488d-986f-023109b1a5b7",
  ); // Write char uuid from app to ESP32
  final _charUUIDReceiver = Guid(
    "a29d643b-4fda-446d-b9fd-118f540a902d",
  ); // Notify char uuid from ESP32 to app

  static final ValueNotifier<Map<BluetoothDevice, BluetoothConnectionState>> _foundDevicesList =
      ValueNotifier<Map<BluetoothDevice, BluetoothConnectionState>>({});

  BluetoothManager({required this._context});

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final requiredPermissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse,
      ];

      try {
        final statuses = await requiredPermissions.request();
        for (final permission in requiredPermissions) {
          if (statuses[permission] != PermissionStatus.granted) {
            if (!_context.mounted) return;

            Toastification().show(
              title: Text(LocaleKeys.alert_notify_permission_title.tr(context: _context)),
              description: Text(
                LocaleKeys.alert_notify_permission_description_not_granted.tr(
                  context: _context,
                  namedArgs: {'permission': permission.toString()},
                ),
              ),
              type: ToastificationType.info,
              style: ToastificationStyle.flat,
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 500),
            );
            throw Exception('Permission $permission not granted');
          }
        }
      } catch (e) {
        if (!_context.mounted) return;

        Toastification().show(
          context: _context,
          title: Text(LocaleKeys.alert_notify_permission_title.tr(context: _context)),
          description: Text(
            LocaleKeys.alert_notify_permission_description_request_fail.tr(context: _context),
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
        throw Exception('Permission request failed: $e');
      }
    }
  }

  Future<bool> initialize() async {
    StreamSubscription<BluetoothAdapterState>? enableBTSub;

    if (!await FlutterBluePlus.isSupported) {
      print("Bluetooth isn't support in this device!");
      return false;
    }

    enableBTSub = FlutterBluePlus.adapterState.listen(
      (state) {
        print("Current bluetooth state: $state");

        if (state == BluetoothAdapterState.on) {
          print("Bluetooth connected! Starting scanning...");
        } else if (state == BluetoothAdapterState.off) {
          if (!_context.mounted) return;

          Toastification().show(
            context: _context,
            title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
            description: Text(
              LocaleKeys.alert_notify_bluetooth_description_request_enable_bt.tr(context: _context),
            ),
            type: ToastificationType.info,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );
        }
      },
      onError: (e) {
        print("Error during bluetooth enable requests: $e");
        enableBTSub?.cancel();
        return false;
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        if (!_context.mounted) return false;

        Toastification().show(
          context: _context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_bt_not_enable.tr(context: _context),
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
        enableBTSub.cancel();
        return false;
      }
    }

    enableBTSub.cancel();
    await _startScanning();
    return true;
  }

  void reinitialize() {
    _startScanning();
  }

  Future<void> _startScanning() async {
    await _requestPermissions();

    _foundDevicesList.value.clear();

    final scanningBTSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult result = results.last;
          BluetoothDevice device = result.device;

          if (!_foundDevicesList.value.containsKey(device)) {
            _foundDevicesList.value[device] = BluetoothConnectionState.disconnected;
            print(
              "Found device: ${device.remoteId} - ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}",
            );
          }
        }
      },
      onError: (e) {
        print("Error during bluetooth scanning: $e");
        return;
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(scanningBTSub);

    await FlutterBluePlus.startScan(timeout: 10.seconds);
    await FlutterBluePlus.isScanning.where((value) => !value).first;

    if (getConnectedDevice != null) {
      BluetoothDevice device = getConnectedDevice!;
      _foundDevicesList.value[device] = BluetoothConnectionState.connected;
      print(
        "Found connected device: ${device.remoteId} - ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}",
      );
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    print("Connecting to device ${device.remoteId}");

    try {
      await device.connect(license: License.nonprofit);
      if (!_context.mounted) return;

      Toastification().show(
        context: _context,
        title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
        description: Text(
          LocaleKeys.alert_notify_bluetooth_description_bt_success_connect.tr(
            context: _context,
            namedArgs: {
              'device': device.platformName.isEmpty
                  ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
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
      print(
        'Connected to device ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}',
      );
      _startBluetoothListener(device);
    } catch (e) {
      _foundDevicesList.value[device] = BluetoothConnectionState.disconnected;
      Toastification().show(
        context: _context,
        title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
        description: Text(
          LocaleKeys.alert_notify_bluetooth_description_bt_fail_connect.tr(
            context: _context,
            namedArgs: {
              'device': device.platformName.isEmpty
                  ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
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
      throw Exception('Connection failed: $e');
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    print("Disconnecting from device ${device.remoteId}");

    if (device.isConnected) {
      try {
        await device.disconnect();
        if (!_context.mounted) return;

        Toastification().show(
          context: _context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_bt_success_disconnect.tr(
              context: _context,
              namedArgs: {
                'device': device.platformName.isEmpty
                    ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
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
        print(
          'Disconnected from device ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}',
        );
      } catch (e) {
        Toastification().show(
          context: _context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_bt_fail_disconnect.tr(
              context: _context,
              namedArgs: {
                'device': device.platformName.isEmpty
                    ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
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
        throw Exception('Disconnection failed: $e');
      }
    } else {
      Toastification().show(
        context: _context,
        title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
        description: Text(
          LocaleKeys.alert_notify_bluetooth_description_bt_already_disconnect.tr(
            context: _context,
            namedArgs: {
              'device': device.platformName.isEmpty
                  ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
                  : device.platformName,
            },
          ),
        ),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 500),
      );
      print('No active connection to disconnect');
    }
  }

  void _startBluetoothListener(BluetoothDevice device) {
    StreamSubscription<BluetoothConnectionState>? connectedBTListenerSub;

    connectedBTListenerSub = device.connectionState.listen(
      (state) async {
        if (state == BluetoothConnectionState.disconnected) {
          _foundDevicesList.value[device] = BluetoothConnectionState.disconnected;
          print(
            "Disconnected from device ${device.platformName} | ${_foundDevicesList.value[device]}",
          );
        } else if (state == BluetoothConnectionState.connected) {
          _foundDevicesList.value[device] = BluetoothConnectionState.connected;
          print("Connected to device ${device.platformName} | ${_foundDevicesList.value[device]}");

          BluetoothCharacteristic deviceReceiverChar = await _getCharacteristic(
            device,
            _charUUIDReceiver,
          );
          deviceReceiverChar.onValueReceived.listen((value) async {
            String decodedData = "";

            try {
              decodedData = utf8.decode(value, allowMalformed: false);
            } catch (e) {
              print("Invalid decoded data! Skipping...");
              return;
            }

            if (decodedData.trim().isEmpty) return;

            print("Received data from ESP32: ${decodedData.trim()}");
            _receivedData.addFirst(decodedData.trim());
          });

          device.cancelWhenDisconnected(
            deviceReceiverChar as StreamSubscription<List<int>>,
            delayed: true,
          );
          await deviceReceiverChar.setNotifyValue(true);
        }
      },
      onError: (e) {
        if (!_context.mounted) return;

        Toastification().show(
          context: _context,
          title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
          description: Text(
            LocaleKeys.alert_notify_bluetooth_description_bt_connection_error.tr(
              context: _context,
              namedArgs: {
                'device': device.platformName.isEmpty
                    ? LocaleKeys.bluetooth_page_unknown_device.tr(context: _context)
                    : device.platformName,
              },
            ),
          ),
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
        print('Connection error: $e');
      },
    );

    device.cancelWhenDisconnected(connectedBTListenerSub, delayed: true);
  }

  void sendBluetoothData(BluetoothDevice device, String data) async {
    BluetoothCharacteristic deviceCharacter = await _getCharacteristic(device, _charUUIDWrite);

    if (device.isConnected) {
      String rawData = data.trim();
      List<int> encodedData = utf8.encode(rawData);
      await deviceCharacter.write(encodedData);
    } else {
      if (!_context.mounted) return;

      Toastification().show(
        context: _context,
        title: Text(LocaleKeys.alert_notify_bluetooth_title.tr(context: _context)),
        description: Text(
          LocaleKeys.alert_notify_bluetooth_description_no_active_bt.tr(context: _context),
        ),
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 500),
      );
      print('No active connection to send message');
    }
  }

  Future<BluetoothCharacteristic> _getCharacteristic(BluetoothDevice device, Guid charUuid) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid == _serviceUUID) {
        for (final character in service.characteristics) {
          if (character.uuid == charUuid) {
            return character;
          }
        }
      }
    }
    throw Exception('Characteristic $charUuid not found on service $_serviceUUID');
  }

  static List<BluetoothDevice> get getDevicesList => _foundDevicesList.value.keys.toList();

  static ValueNotifier<Map<BluetoothDevice, BluetoothConnectionState>> get getDeviceStatus =>
      _foundDevicesList;

  static String get getReceivedData {
    return _receivedData.isEmpty ? "" : _receivedData.removeFirst();
  }

  static bool get isBluetoothConnected =>
      FlutterBluePlus.connectedDevices.any((device) => device.isConnected);

  static BluetoothDevice? get getConnectedDevice =>
      FlutterBluePlus.connectedDevices.where((device) => device.isConnected).firstOrNull;
}
