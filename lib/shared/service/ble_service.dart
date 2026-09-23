import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

enum BleConnectionState { disconnected, disconnecting, connecting, connected }

enum BlePermissionStatus { request_success, request_failed, request_denied, not_support }

enum BleConnectionStatus {
  success_connect,
  success_disconnect,
  no_device_connected,
  failed_connect,
  failed_disconnect,
}

enum BleStatus {
  bt_not_support,
  scanning_success,
  initialize_success,
  initialize_failed,
  ble_stream_sub_error,
}

class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  final _serviceUUID = Guid(
    "3707a02f-16d0-4b0f-8465-540cf4f1e049",
  ); // Service char uuid of Bluetooth
  final _charUUIDWrite = Guid(
    "d62cc1aa-931c-488d-986f-023109b1a5b7",
  ); // Write char uuid from app to ESP32
  final _charUUIDReceiver = Guid(
    "a29d643b-4fda-446d-b9fd-118f540a902d",
  ); // Notify char uuid from ESP32 to app

  static const String _prefLastDeviceId = 'last_connected_device_id';

  BluetoothDevice? _activeDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothAdapterState>? _btAdapterStateSub;
  StreamSubscription<List<int>>? _btValueReceiverSub;

  bool _isManualDisconnect = false;
  bool _isAutoReconnectEnable = false;

  final ValueNotifier<Map<BluetoothDevice, BleConnectionState>> foundDevicesList =
      ValueNotifier<Map<BluetoothDevice, BleConnectionState>>({});
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSub;
  final ValueNotifier<BleConnectionState> activeConnectionState = ValueNotifier<BleConnectionState>(
    BleConnectionState.disconnected,
  );

  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();

  late SharedPreferencesAsync _settingPrefs;

  Future<BleStatus> initialize() async {
    if (!await FlutterBluePlus.isSupported) {
      print("Bluetooth isn't support in this device!");
      return BleStatus.bt_not_support;
    }

    _btAdapterStateSub?.cancel();
    _btAdapterStateSub = FlutterBluePlus.adapterState.listen(
      (state) {
        print("Bluetooth adapter state changed: $state");

        if (state == BluetoothAdapterState.on) {
          print("Bluetooth is on.");
          if (_activeDevice == null || !_activeDevice!.isConnected) {
            _reconnectLastDevice();
          }
        } else if (state == BluetoothAdapterState.off) {
          print("Bluetooth is off.");
        }
      },
      onError: (e) {
        print("Error during bluetooth adapter state stream: $e");
        return BleStatus.ble_stream_sub_error;
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        print("Error during bluetooth turn on: $e");
      }
    }

    final prefsOption = const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
        fileName: 'settings_data',
      ),
    );
    _settingPrefs = SharedPreferencesAsync(options: prefsOption);

    bool? autoReconnectBT = await _settingPrefs.getBool('autoReconnectBT');
    _isAutoReconnectEnable = autoReconnectBT ?? false;
    return BleStatus.initialize_success;
  }

  Future<({BlePermissionStatus status, Permission? permission})> requestPermissions() async {
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
            print("Permission denied: $permission");
            return (status: BlePermissionStatus.request_denied, permission: permission);
          }
        }
        return (status: BlePermissionStatus.request_success, permission: null);
      } catch (e) {
        return (status: BlePermissionStatus.request_failed, permission: null);
      }
    }
    return (status: BlePermissionStatus.not_support, permission: null);
  }

  Future<BleStatus> startScanning() async {
    final currentMap = <BluetoothDevice, BleConnectionState>{};
    if (_activeDevice != null && _activeDevice!.isConnected) {
      currentMap[_activeDevice!] = BleConnectionState.connected;
    }
    foundDevicesList.value = currentMap;

    final btScanResultSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult result = results.last;
          BluetoothDevice device = result.device;

          if (!foundDevicesList.value.containsKey(device)) {
            foundDevicesList.value = Map.from(foundDevicesList.value)
              ..[device] = BleConnectionState.disconnected;
            print(
              "Found device: ${device.remoteId} - ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}",
            );
          }
        }
      },
      onError: (e) {
        print("Error during bluetooth scan result stream: $e");
        return BleStatus.ble_stream_sub_error;
      },
      cancelOnError: true,
    );

    FlutterBluePlus.cancelWhenScanComplete(btScanResultSub);
    await FlutterBluePlus.startScan(timeout: 10.seconds);
    await FlutterBluePlus.isScanning.where((value) => !value).first;
    return BleStatus.scanning_success;
  }

  Future<BleConnectionStatus> connectToDevice(BluetoothDevice device) async {
    print("Connecting to device ${device.remoteId}");

    _updateDeviceState(device, BleConnectionState.connecting);

    try {
      await device.connect(license: License.nonprofit, mtu: 517);
      _activeDevice = device;

      await _settingPrefs.setString('last_connected_device_id', device.remoteId.str);

      await _setupServicesAndCharacteristics(device);
      _listenToConnectionChanges(device);

      print(
        'Connected to device ${device.platformName.isEmpty ? "Unknown Device" : device.platformName}',
      );
      _updateDeviceState(device, BleConnectionState.connected);
      return BleConnectionStatus.success_connect;
    } catch (e) {
      print("Connection failed: $e");
      _updateDeviceState(device, BleConnectionState.disconnected);
      return BleConnectionStatus.failed_connect;
    }
  }

  Future<BleConnectionStatus> disconnectFromDevice() async {
    _deviceConnectionSub?.cancel();
    _btValueReceiverSub?.cancel();

    _isManualDisconnect = true;

    if (_activeDevice != null) {
      final device = _activeDevice!;
      _updateDeviceState(device, BleConnectionState.disconnecting);

      print("Disconnecting from device ${device.remoteId}");

      try {
        await device.disconnect();
      } catch (e) {
        print("Disconnection failed: $e");
      } finally {
        _updateDeviceState(device, BleConnectionState.disconnected);
        _writeCharacteristic = null;
        _activeDevice = null;
      }

      return BleConnectionStatus.success_disconnect;
    }

    return BleConnectionStatus.no_device_connected;
  }

  Future<void> _startAutoReconnect(BluetoothDevice device) async {
    int attempt = 0;
    const maxAttempts = 15;

    print("Starting auto-reconnect for ${device.remoteId}...");

    while (!device.isConnected && attempt < maxAttempts) {
      attempt++;
      _updateDeviceState(device, BleConnectionState.connecting);

      final delay = (attempt * 2).clamp(2, 10);
      await Future.delayed(Duration(seconds: delay));

      if (_isManualDisconnect) break;

      try {
        print("Reconnecting... Attempt $attempt");
        await device.connect(
          license: License.nonprofit,
          mtu: 517,
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );

        if (device.isConnected) {
          print("Successfully reconnected to ${device.remoteId}");
          await _setupServicesAndCharacteristics(device);
          _listenToConnectionChanges(device);
          _updateDeviceState(device, BleConnectionState.connected);
          return;
        }
      } catch (e) {
        print("Reconnect attempt $attempt failed: $e");
      }
    }

    _updateDeviceState(device, BleConnectionState.disconnected);
  }

  Future<void> _reconnectLastDevice() async {
    if (_activeDevice != null && _activeDevice!.isConnected) return;

    final savedId = await _settingPrefs.getString(_prefLastDeviceId);

    if (savedId != null && savedId.isNotEmpty) {
      print("Found saved device ID: $savedId. Reconnecting...");
      final device = BluetoothDevice.fromId(savedId);
      await connectToDevice(device);
    }
  }

  void _listenToConnectionChanges(BluetoothDevice device) {
    _deviceConnectionSub?.cancel();
    _deviceConnectionSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _updateDeviceState(device, BleConnectionState.disconnected);
        _btValueReceiverSub?.cancel();
        _writeCharacteristic = null;

        if (_isAutoReconnectEnable) {
          print("Unexpected disconnect detected! Trying to reconnecting to bluetooth device....");
          _startAutoReconnect(device);
        }
      }
    });
  }

  Future<bool> sendBluetoothData(BluetoothDevice device, String data) async {
    if (_activeDevice == null || !_activeDevice!.isConnected || _writeCharacteristic == null) {
      debugPrint("No active connection to send data.");
      return false;
    }

    try {
      String rawData = data.trim();
      List<int> encodedData = utf8.encode(rawData);
      await _writeCharacteristic!.write(encodedData);
      return true;
    } catch (e) {
      print("Error sending data: $e");
      return false;
    }
  }

  Future<void> _setupServicesAndCharacteristics(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid == _serviceUUID) {
        for (final character in service.characteristics) {
          if (character.uuid == _charUUIDWrite) {
            _writeCharacteristic = character;
          }

          if (character.uuid == _charUUIDReceiver) {
            await character.setNotifyValue(true);
            _btValueReceiverSub?.cancel();
            _btValueReceiverSub = character.onValueReceived.listen((value) {
              try {
                final receivedData = utf8.decode(value, allowMalformed: false).trim();
                if (receivedData.isNotEmpty) {
                  _dataStreamController.add(receivedData);
                }
              } catch (e) {
                print('Error decoding received data: $e');
              }
            });
          }
        }
      }
    }
  }

  void _updateDeviceState(BluetoothDevice device, BleConnectionState state) {
    foundDevicesList.value = Map.from(foundDevicesList.value)..[device] = state;
  }

  void dispose() {
    _deviceConnectionSub?.cancel();
    _btAdapterStateSub?.cancel();
    _btValueReceiverSub?.cancel();
    _dataStreamController.close();
  }

  BluetoothDevice? get connectedDevice => _activeDevice;

  bool get isConnected => _activeDevice?.isConnected ?? false;

  Stream<String> get dataStream => _dataStreamController.stream;
}
