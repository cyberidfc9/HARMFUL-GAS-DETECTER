import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'gas_monitor_theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_key, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_key, 'light');
    } else {
      await prefs.setString(_key, 'system');
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class DeviceIdNotifier extends Notifier<String> {
  static const _key = 'gas_monitor_device_id';

  @override
  String build() {
    _load();
    return 'esp32_gas_01';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.trim().isNotEmpty) {
      state = saved.trim();
    }
  }

  Future<void> setDeviceId(String id) async {
    state = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state);
  }
}

final deviceIdProvider =
    NotifierProvider<DeviceIdNotifier, String>(DeviceIdNotifier.new);

class HeartbeatTimeoutNotifier extends Notifier<int> {
  @override
  int build() => 90;

  void setTimeout(int seconds) => state = seconds;
}

final heartbeatTimeoutProvider =
    NotifierProvider<HeartbeatTimeoutNotifier, int>(HeartbeatTimeoutNotifier.new);

class CustomPathNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setPath(String path) => state = path;
}

final customPathProvider =
    NotifierProvider<CustomPathNotifier, String>(CustomPathNotifier.new);

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool enabled) => state = enabled;
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
        NotificationsEnabledNotifier.new);
