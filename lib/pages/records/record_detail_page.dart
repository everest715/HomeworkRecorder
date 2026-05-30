import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/records_provider.dart';
import '../../providers/database_provider.dart';
import '../../utils/formatters.dart';

class RecordDetailPage extends ConsumerWidget {
  final StudyRecord record;

  const RecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(ratingForRecordProvider(record.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条学习记录吗？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(recordsDaoProvider).deleteRecord(record.id);
                ref.invalidate(todayRecordsProvider);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          ref.read(subjectsDaoProvider).getSubjectById(record.subjectId),
          ref.read(subjectsDaoProvider).getStudyTypeById(record.typeId),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subject = snapshot.data![0] as Subject;
          final studyType = snapshot.data![1] as StudyType;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.icon} ${subject.name}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('类型: ${studyType.name}'),
                      Text('日期: ${formatDate(record.date)} ${formatTime(record.date)}'),
                      Text('时长: ${formatDuration(record.durationSeconds)}'),
                      Text('模式: ${record.timerMode == 'countup' ? '正计时' : '倒计时'}'),
                      if (record.targetSeconds != null)
                        Text('目标时长: ${formatDuration(record.targetSeconds!)}'),
                      if (record.note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('备注: ${record.note}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('完成情况', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ratingAsync.when(
                data: (rating) {
                  if (rating == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('未录入完成情况'),
                      ),
                    );
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _RatingRow(label: '🎯 正确率', value: rating.accuracy),
                          _RatingRow(label: '🧠 专注度', value: rating.focus),
                          _RatingRow(label: '⚡ 完成速度', value: rating.speed),
                          _RatingRow(label: '💪 难易度', value: rating.difficulty),
                          if (rating.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('备注: ${rating.note}'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('加载评分失败'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int value;

  const _RatingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 24, child: Text('$value/5')),
        ],
      ),
    );
  }
}
