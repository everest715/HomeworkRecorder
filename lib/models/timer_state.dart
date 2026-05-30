/// 计时器模式
enum TimerMode { countup, countdown }

/// 计时器运行状态
enum TimerStatus { idle, running, paused }

/// 计时器完整状态
class TimerState {
  final TimerMode mode;
  final TimerStatus status;
  final int elapsedSeconds;
  final int? targetSeconds;
  final String? subjectId;
  final String? typeId;

  const TimerState({
    this.mode = TimerMode.countup,
    this.status = TimerStatus.idle,
    this.elapsedSeconds = 0,
    this.targetSeconds,
    this.subjectId,
    this.typeId,
  });

  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? elapsedSeconds,
    int? targetSeconds,
    String? subjectId,
    String? typeId,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      subjectId: subjectId ?? this.subjectId,
      typeId: typeId ?? this.typeId,
    );
  }
}
