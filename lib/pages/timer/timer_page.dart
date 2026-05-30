import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';
import '../../widgets/timer_display.dart';
import 'completion_sheet.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final subjectsAsync = ref.watch(visibleSubjectsProvider);
    final typesAsync = ref.watch(allStudyTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('计时')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 科目选择
          subjectsAsync.when(
            data: (subjects) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: subjects.map((s) {
                  final selected = timerState.subjectId == s.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text('${s.icon} ${s.name}'),
                      onSelected: (_) => ref
                          .read(timerProvider.notifier)
                          .setSubject(s.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          // 类型选择
          typesAsync.when(
            data: (types) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: types.map((t) {
                  final selected = timerState.typeId == t.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(t.name),
                      onSelected: (_) => ref
                          .read(timerProvider.notifier)
                          .setType(t.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          // 模式切换
          SegmentedButton<TimerMode>(
            segments: const [
              ButtonSegment(value: TimerMode.countup, label: Text('正计时')),
              ButtonSegment(value: TimerMode.countdown, label: Text('倒计时')),
            ],
            selected: {timerState.mode},
            onSelectionChanged: (modes) =>
                ref.read(timerProvider.notifier).setMode(modes.first),
          ),
          if (timerState.mode == TimerMode.countdown) ...[
            const SizedBox(height: 8),
            Text(
              '目标: ${timerState.targetSeconds != null ? '${timerState.targetSeconds! ~/ 60} 分钟' : '未设置'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: (timerState.targetSeconds ?? 1800) / 60,
              min: 5,
              max: 120,
              divisions: 23,
              label: '${((timerState.targetSeconds ?? 1800) ~/ 60)} 分钟',
              onChanged: (v) => ref
                  .read(timerProvider.notifier)
                  .setTargetSeconds((v * 60).round()),
            ),
          ],
          const SizedBox(height: 32),
          // 计时显示
          TimerDisplay(
            elapsedSeconds: timerState.elapsedSeconds,
            targetSeconds: timerState.targetSeconds,
            isCountdown: timerState.mode == TimerMode.countdown,
          ),
          const SizedBox(height: 32),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timerState.status == TimerStatus.idle)
                FilledButton.icon(
                  onPressed: timerState.subjectId != null && timerState.typeId != null
                      ? () => ref.read(timerProvider.notifier).start()
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                ),
              if (timerState.status == TimerStatus.running) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(timerProvider.notifier).pause(),
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () =>
                      _stopAndSave(context, ref, timerState),
                  icon: const Icon(Icons.stop),
                  label: const Text('结束'),
                ),
              ],
              if (timerState.status == TimerStatus.paused) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(timerProvider.notifier).resume(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () =>
                      _stopAndSave(context, ref, timerState),
                  icon: const Icon(Icons.stop),
                  label: const Text('结束'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _stopAndSave(
      BuildContext context, WidgetRef ref, TimerState timerState) {
    ref.read(timerProvider.notifier).stop();
    if (timerState.subjectId != null && timerState.elapsedSeconds > 0) {
      final record = StudyRecordsCompanion.insert(
        id: const Uuid().v4(),
        subjectId: timerState.subjectId!,
        typeId: timerState.typeId ?? 't1',
        date: DateTime.now(),
        durationSeconds: timerState.elapsedSeconds,
        timerMode: timerState.mode.name,
        targetSeconds: drift.Value(timerState.targetSeconds),
      );
      ref.read(recordsDaoProvider).insertRecord(record).then((recordId) {
        ref.read(timerProvider.notifier).fullReset();
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CompletionSheet(recordId: recordId),
          );
        }
      });
    } else {
      ref.read(timerProvider.notifier).fullReset();
    }
  }
}
