import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_provider.dart';
import '../../providers/database_provider.dart';
import '../../utils/formatters.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(statsViewRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: Column(
        children: [
          // 范围选择
          SegmentedButton<StatsViewRange>(
            segments: const [
              ButtonSegment(value: StatsViewRange.week, label: Text('周')),
              ButtonSegment(value: StatsViewRange.month, label: Text('月')),
              ButtonSegment(value: StatsViewRange.semester, label: Text('学期')),
            ],
            selected: {range},
            onSelectionChanged: (ranges) =>
                ref.read(statsViewRangeProvider.notifier).state = ranges.first,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('学习时长',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _DailyBarChart(),
                  const SizedBox(height: 24),
                  Text('科目分布',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _SubjectPieChart(),
                  const SizedBox(height: 24),
                  Text('综合评分',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _AverageRatingsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailyDurationsProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('暂无数据')),
            ),
          );
        }
        final maxMinutes = data.map((d) => d.totalSeconds / 60).reduce((a, b) => a > b ? a : b);
        final chartMaxY = (maxMinutes * 1.2).ceilToDouble();
        final interval = _niceInterval(chartMaxY);

        final spots = data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value.totalSeconds / 60).toDouble(),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ))
            .toList();

        return Card(
          child: SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(BarChartData(
                maxY: chartMaxY,
                barGroups: spots,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (v, _) {
                        if (v >= 60) {
                          return Text('${(v / 60).toStringAsFixed(1)}h');
                        }
                        return Text('${v.toInt()}m');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        if (v.toInt() < data.length) {
                          return Text(formatDate(data[v.toInt()].date));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
              )),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 200, child: Center(child: Text('加载失败'))),
    );
  }

  /// 计算美观的刻度间隔
  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final rough = maxY / 4;
    final magnitude = pow(10, (log(rough) / log(10)).floor()).toDouble();
    final residual = rough / magnitude;
    double nice;
    if (residual <= 1.5) {
      nice = 1 * magnitude;
    } else if (residual <= 3) {
      nice = 2 * magnitude;
    } else if (residual <= 7) {
      nice = 5 * magnitude;
    } else {
      nice = 10 * magnitude;
    }
    return nice;
  }
}

class _SubjectPieChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(subjectDurationsProvider);
    final subjectsDao = ref.watch(subjectsDaoProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('暂无数据')),
            ),
          );
        }
        return Card(
          child: SizedBox(
            height: 200,
            child: FutureBuilder(
              future: subjectsDao.getAllSubjects(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subjectMap = {for (var s in snapshot.data!) s.id: s};
                final colors = [
                  Colors.orange, Colors.red, Colors.purple,
                  Colors.blue, Colors.green, Colors.lightGreen,
                  Colors.brown, Colors.teal, Colors.blueGrey,
                ];

                return PieChart(PieChartData(
                  sections: data.asMap().entries.map((e) {
                    final subject = subjectMap[e.value.subjectId];
                    return PieChartSectionData(
                      value: e.value.totalSeconds.toDouble(),
                      title: subject?.name ?? '',
                      color: colors[e.key % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ));
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 200, child: Center(child: Text('加载失败'))),
    );
  }
}

class _AverageRatingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(averageRatingsProvider);

    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('暂无评分数据')),
            ),
          );
        }
        final r = ratings.first;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _RatingBar(label: '🎯 正确率', value: r.avgAccuracy),
                _RatingBar(label: '🧠 专注度', value: r.avgFocus),
                _RatingBar(label: '⚡ 完成速度', value: r.avgSpeed),
                _RatingBar(label: '💪 难易度', value: r.avgDifficulty),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('加载失败')),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

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
          SizedBox(width: 40, child: Text(value.toStringAsFixed(1))),
        ],
      ),
    );
  }
}
