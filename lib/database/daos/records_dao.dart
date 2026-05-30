import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'records_dao.g.dart';

@DriftAccessor(tables: [StudyRecords, CompletionRatings])
class RecordsDao extends DatabaseAccessor<AppDatabase>
    with _$RecordsDaoMixin {
  RecordsDao(super.db);

  Future<List<StudyRecord>> getRecordsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  Future<CompletionRating?> getRatingForRecord(String recordId) {
    return (select(completionRatings)
          ..where((r) => r.recordId.equals(recordId)))
        .getSingleOrNull();
  }

  Future<String> insertRecord(StudyRecordsCompanion record) async {
    await into(studyRecords).insert(record);
    return record.id.value;
  }

  Future<void> insertRating(CompletionRatingsCompanion rating) async {
    await into(completionRatings).insert(rating);
  }

  Future<void> updateRecord(StudyRecordsCompanion record) async {
    await (update(studyRecords)
          ..where((r) => r.id.equals(record.id.value)))
        .write(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await (delete(completionRatings)
          ..where((r) => r.recordId.equals(recordId)))
        .go();
    await (delete(studyRecords)..where((r) => r.id.equals(recordId))).go();
  }

  Future<List<StudyRecord>> getRecordsInRange(DateTime start, DateTime end) {
    return (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .get();
  }
}
