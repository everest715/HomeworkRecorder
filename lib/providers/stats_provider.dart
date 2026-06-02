import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/stats_dao.dart';
import 'database_provider.dart';

enum StatsViewRange { week, month, semester }

final statsViewRangeProvider =
    StateProvider<StatsViewRange>((ref) => StatsViewRange.week);

final statsStartDateProvider =
    StateProvider<DateTime>((ref) => _startOfCurrentWeek());

/// 统计数据变更的刷新触发器（记录变更时 +1 即可刷新所有统计图）
final statsRefreshProvider = StateProvider<int>((ref) => 0);

DateTime _startOfCurrentWeek() {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
}

final dailyDurationsProvider =
    FutureProvider.autoDispose<List<DailyDuration>>((ref) async {
  ref.watch(statsRefreshProvider); // 记录变更时自动重新查询
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getDailyDurations(start, end);
});

final subjectDurationsProvider =
    FutureProvider.autoDispose<List<SubjectDuration>>((ref) async {
  ref.watch(statsRefreshProvider); // 记录变更时自动重新查询
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getSubjectDurations(start, end);
});

final averageRatingsProvider =
    FutureProvider.autoDispose<List<AverageRatings>>((ref) async {
  ref.watch(statsRefreshProvider); // 记录变更时自动重新查询
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getAverageRatings(start, end);
});

final daySummaryProvider =
    FutureProvider.autoDispose.family<DaySummary, DateTime>(
  (ref, date) async {
    final dao = ref.watch(statsDaoProvider);
    return dao.getDaySummary(date);
  },
);

DateTime _endOfRange(DateTime start, StatsViewRange range) {
  switch (range) {
    case StatsViewRange.week:
      return start.add(const Duration(days: 7));
    case StatsViewRange.month:
      return DateTime(start.year, start.month + 1, 1);
    case StatsViewRange.semester:
      return DateTime(start.year, start.month + 6, 1);
  }
}
