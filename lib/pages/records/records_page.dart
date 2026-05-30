import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../database/daos/subjects_dao.dart';
import '../../database/daos/stats_dao.dart';
import '../../providers/records_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/stats_provider.dart';
import '../../utils/formatters.dart';
import 'record_detail_page.dart';

class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(todayRecordsProvider);
    final daySummaryAsync = ref.watch(daySummaryProvider(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${DateTime.now().month}月${DateTime.now().day}日 · 今日学习',
        ),
      ),
      body: Column(
        children: [
          // 概览卡片
          daySummaryAsync.when(
            data: (summary) => _OverviewCard(summary: summary),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // 记录列表
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return const Center(
                    child: Text('还没有学习记录，去计时页面开始吧！'),
                  );
                }
                return FutureBuilder(
                  future: _loadRecordsWithDetails(
                      records, ref.read(subjectsDaoProvider)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return _RecordTile(
                          item: item,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordDetailPage(record: item.record),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<_RecordItem>> _loadRecordsWithDetails(
    List<StudyRecord> records,
    SubjectsDao subjectsDao,
  ) async {
    final items = <_RecordItem>[];
    for (final record in records) {
      final subject = await subjectsDao.getSubjectById(record.subjectId);
      final studyType = await subjectsDao.getStudyTypeById(record.typeId);
      items.add(_RecordItem(
        record: record,
        subject: subject,
        studyType: studyType,
      ));
    }
    return items;
  }
}

class _OverviewCard extends StatelessWidget {
  final DaySummary summary;

  const _OverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: '学习时长',
              value: formatDuration(summary.totalSeconds),
            ),
            _StatItem(
              label: '完成数',
              value: '${summary.recordCount}',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecordItem {
  final StudyRecord record;
  final Subject subject;
  final StudyType studyType;

  _RecordItem({
    required this.record,
    required this.subject,
    required this.studyType,
  });
}

class _RecordTile extends StatelessWidget {
  final _RecordItem item;
  final VoidCallback onTap;

  const _RecordTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _parseColor(item.subject.color),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.subject.icon} ${item.subject.name} · ${item.studyType.name}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      formatTime(item.record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                formatDuration(item.record.durationSeconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
