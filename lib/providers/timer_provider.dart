import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import 'settings_provider.dart';

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const TimerState();
  }

  void setSubject(String subjectId) {
    state = state.copyWith(subjectId: subjectId);
  }

  void setType(String typeId) {
    state = state.copyWith(typeId: typeId);
  }

  void setMode(TimerMode mode) {
    // 切换到倒计时时，如果未设置目标则使用设置中的默认值
    if (mode == TimerMode.countdown && state.targetSeconds == null) {
      final settings = ref.read(settingsProvider).valueOrNull;
      final defaultMinutes = settings?.defaultCountdownMinutes ?? 30;
      state = state.copyWith(mode: mode, targetSeconds: defaultMinutes * 60);
    } else {
      state = state.copyWith(mode: mode);
    }
  }

  void setTargetSeconds(int seconds) {
    state = state.copyWith(targetSeconds: seconds);
  }

  void start() {
    state = state.copyWith(status: TimerStatus.running);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      if (state.mode == TimerMode.countdown &&
          state.targetSeconds != null &&
          state.elapsedSeconds >= state.targetSeconds!) {
        _timer?.cancel();
        state = state.copyWith(status: TimerStatus.idle);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() {
    start();
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.idle);
  }

  void reset() {
    _timer?.cancel();
    state = const TimerState();
  }

  void fullReset() {
    _timer?.cancel();
    state = const TimerState();
  }
}
