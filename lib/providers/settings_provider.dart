import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../models/timer_state.dart';

const _keyRole = 'user_role';
const _keyTimerMode = 'default_timer_mode';
const _keyCountdownMinutes = 'default_countdown_minutes';
const _keyCloudSync = 'cloud_sync_enabled';
const _keyThemeMode = 'theme_mode';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      currentRole: UserRole.values[prefs.getInt(_keyRole) ?? 0],
      defaultTimerMode:
          TimerMode.values[prefs.getInt(_keyTimerMode) ?? 0],
      defaultCountdownMinutes:
          prefs.getInt(_keyCountdownMinutes) ?? 30,
      cloudSyncEnabled: prefs.getBool(_keyCloudSync) ?? false,
      themeMode: ThemeMode.values[prefs.getInt(_keyThemeMode) ?? 2],
    );
  }

  Future<void> setRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRole, role.index);
    state = AsyncData(state.value!.copyWith(currentRole: role));
  }

  Future<void> setDefaultTimerMode(TimerMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimerMode, mode.index);
    state = AsyncData(state.value!.copyWith(defaultTimerMode: mode));
  }

  Future<void> setDefaultCountdownMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCountdownMinutes, minutes);
    state = AsyncData(state.value!.copyWith(defaultCountdownMinutes: minutes));
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCloudSync, enabled);
    state = AsyncData(state.value!.copyWith(cloudSyncEnabled: enabled));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }
}
