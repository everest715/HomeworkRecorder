import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final todayProvider = Provider<DateTime>((ref) => DateTime.now());

final todayRecordsProvider =
    FutureProvider.autoDispose<List<StudyRecord>>((ref) async {
  final dao = ref.watch(recordsDaoProvider);
  final today = ref.watch(todayProvider);
  return dao.getRecordsForDate(today);
});

final ratingForRecordProvider =
    FutureProvider.autoDispose.family<CompletionRating?, String>(
  (ref, recordId) async {
    final dao = ref.watch(recordsDaoProvider);
    return dao.getRatingForRecord(recordId);
  },
);

final addRecordProvider =
    FutureProvider.autoDispose.family<void, StudyRecordsCompanion>(
  (ref, record) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.insertRecord(record);
    ref.invalidate(todayRecordsProvider);
  },
);

final addRatingProvider =
    FutureProvider.autoDispose.family<void, CompletionRatingsCompanion>(
  (ref, rating) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.insertRating(rating);
    ref.invalidate(todayRecordsProvider);
  },
);

final deleteRecordProvider =
    FutureProvider.autoDispose.family<void, String>(
  (ref, recordId) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.deleteRecord(recordId);
    ref.invalidate(todayRecordsProvider);
  },
);

final recordsInRangeProvider =
    FutureProvider.autoDispose.family<List<StudyRecord>, DateRange>(
  (ref, range) async {
    final dao = ref.watch(recordsDaoProvider);
    return dao.getRecordsInRange(range.start, range.end);
  },
);

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange({required this.start, required this.end});
}
