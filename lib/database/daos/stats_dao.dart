import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'stats_dao.g.dart';

@DriftAccessor(tables: [StudyRecords, CompletionRatings, Subjects])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  /// 按天聚合学习时长
  Future<List<DailyDuration>> getDailyDurations(DateTime start, DateTime end) async {
    // 先查出范围内所有记录，在 Dart 侧按日期聚合
    final records = await (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end)))
        .get();

    final map = <String, int>{};
    for (final r in records) {
      final dayKey = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      map[dayKey] = (map[dayKey] ?? 0) + r.durationSeconds;
    }

    final result = map.entries.map((e) {
      final parts = e.key.split('-');
      return DailyDuration(
        date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        totalSeconds: e.value,
      );
    }).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<List<SubjectDuration>> getSubjectDurations(DateTime start, DateTime end) async {
    final query = selectOnly(studyRecords)
      ..addColumns([studyRecords.subjectId, studyRecords.durationSeconds.sum()])
      ..where(studyRecords.date.isBiggerOrEqualValue(start))
      ..where(studyRecords.date.isSmallerThanValue(end))
      ..groupBy([studyRecords.subjectId]);

    final rows = await query.get();
    return rows.map((row) => SubjectDuration(
      subjectId: row.read(studyRecords.subjectId)!,
      totalSeconds: row.read(studyRecords.durationSeconds.sum()) ?? 0,
    )).toList();
  }

  Future<List<AverageRatings>> getAverageRatings(DateTime start, DateTime end) async {
    final query = select(completionRatings).join([
      innerJoin(studyRecords, studyRecords.id.equalsExp(completionRatings.recordId)),
    ])
      ..where(studyRecords.date.isBiggerOrEqualValue(start))
      ..where(studyRecords.date.isSmallerThanValue(end));

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final avgAccuracy = rows.map((r) => r.readTable(completionRatings).accuracy).reduce((a, b) => a + b) / rows.length;
    final avgFocus = rows.map((r) => r.readTable(completionRatings).focus).reduce((a, b) => a + b) / rows.length;
    final avgSpeed = rows.map((r) => r.readTable(completionRatings).speed).reduce((a, b) => a + b) / rows.length;
    final avgDifficulty = rows.map((r) => r.readTable(completionRatings).difficulty).reduce((a, b) => a + b) / rows.length;

    return [AverageRatings(
      avgAccuracy: avgAccuracy,
      avgFocus: avgFocus,
      avgSpeed: avgSpeed,
      avgDifficulty: avgDifficulty,
    )];
  }

  Future<DaySummary> getDaySummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final records = await (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end)))
        .get();

    final totalSeconds = records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
    return DaySummary(totalSeconds: totalSeconds, recordCount: records.length);
  }
}

class DailyDuration {
  final DateTime date;
  final int totalSeconds;
  DailyDuration({required this.date, required this.totalSeconds});
}

class SubjectDuration {
  final String subjectId;
  final int totalSeconds;
  SubjectDuration({required this.subjectId, required this.totalSeconds});
}

class AverageRatings {
  final double avgAccuracy;
  final double avgFocus;
  final double avgSpeed;
  final double avgDifficulty;
  AverageRatings({
    required this.avgAccuracy,
    required this.avgFocus,
    required this.avgSpeed,
    required this.avgDifficulty,
  });
}

class DaySummary {
  final int totalSeconds;
  final int recordCount;
  DaySummary({required this.totalSeconds, required this.recordCount});
}
