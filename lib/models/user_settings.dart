import 'timer_state.dart';

/// 用户角色
enum UserRole { parent, child }

/// 主题模式
enum ThemeMode { light, dark, system }

/// 用户设置
class UserSettings {
  final UserRole currentRole;
  final TimerMode defaultTimerMode;
  final int defaultCountdownMinutes;
  final bool cloudSyncEnabled;
  final ThemeMode themeMode;

  const UserSettings({
    this.currentRole = UserRole.parent,
    this.defaultTimerMode = TimerMode.countup,
    this.defaultCountdownMinutes = 30,
    this.cloudSyncEnabled = false,
    this.themeMode = ThemeMode.system,
  });

  UserSettings copyWith({
    UserRole? currentRole,
    TimerMode? defaultTimerMode,
    int? defaultCountdownMinutes,
    bool? cloudSyncEnabled,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      currentRole: currentRole ?? this.currentRole,
      defaultTimerMode: defaultTimerMode ?? this.defaultTimerMode,
      defaultCountdownMinutes:
          defaultCountdownMinutes ?? this.defaultCountdownMinutes,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
