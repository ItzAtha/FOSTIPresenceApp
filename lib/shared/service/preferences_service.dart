import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

class PreferencesService {
  PreferencesService._internal();
  static final PreferencesService instance = PreferencesService._internal();

  late SharedPreferencesAsync _preferences;

  final ValueNotifier<int> btReconnectRetriesNotifier = ValueNotifier<int>(3);
  final ValueNotifier<bool> btAutoReconnectNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> simExpiredNotifyNotifier = ValueNotifier<bool>(true);

  Future<void> init() async {
    final prefsOption = const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
        fileName: 'settings_data',
      ),
    );

    _preferences = SharedPreferencesAsync(options: prefsOption);

    btReconnectRetriesNotifier.value = await _preferences.getInt('maxBTReconnectRetries') ?? 3;
    btAutoReconnectNotifier.value = await _preferences.getBool('autoReconnectBT') ?? false;
    simExpiredNotifyNotifier.value = await _preferences.getBool('notifySIMExpired') ?? true;
  }

  Future<void> setBTAutoReconnect(bool value) async {
    await _preferences.setBool('autoReconnectBT', value);
    btAutoReconnectNotifier.value = value;
  }

  Future<void> setBTMaxRetries(int value) async {
    await _preferences.setInt('maxBTReconnectRetries', value);
    btReconnectRetriesNotifier.value = value;
  }

  Future<void> setSIMExpiredNotify(bool value) async {
    await _preferences.setBool('notifySIMExpired', value);
    simExpiredNotifyNotifier.value = value;
  }
}