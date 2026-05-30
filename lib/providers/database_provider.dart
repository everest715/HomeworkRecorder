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

/// 科目列表变更的刷新触发器
final subjectsRefreshProvider = StateProvider<int>((ref) => 0);

/// 响应式科目列表
final allSubjectsProvider = FutureProvider.autoDispose<List<Subject>>((ref) async {
  // watch 刷新触发器，变更时自动重新获取
  ref.watch(subjectsRefreshProvider);
  return ref.read(subjectsDaoProvider).getAllSubjects();
});

/// 类型列表变更的刷新触发器
final studyTypesRefreshProvider = StateProvider<int>((ref) => 0);

/// 响应式类型列表
final allStudyTypesProvider = FutureProvider.autoDispose<List<StudyType>>((ref) async {
  ref.watch(studyTypesRefreshProvider);
  return ref.read(subjectsDaoProvider).getAllStudyTypes();
});
