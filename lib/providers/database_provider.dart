import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final recordsDaoProvider = Provider((ref) => ref.watch(databaseProvider).recordsDao);
final subjectsDaoProvider = Provider((ref) => ref.watch(databaseProvider).subjectsDao);
final statsDaoProvider = Provider((ref) => ref.watch(databaseProvider).statsDao);
