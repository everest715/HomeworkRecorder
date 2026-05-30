import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects, StudyTypes])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  /// 获取未隐藏的科目（计时页使用）
  Future<List<Subject>> getVisibleSubjects() {
    return (select(subjects)
          ..where((s) => s.isHidden.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  Future<List<StudyType>> getAllStudyTypes() {
    return (select(studyTypes)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<Subject> getSubjectById(String id) {
    return (select(subjects)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<StudyType> getStudyTypeById(String id) {
    return (select(studyTypes)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<String> insertSubject(SubjectsCompanion subject) async {
    await into(subjects).insert(subject);
    return subject.id.value;
  }

  Future<String> insertStudyType(StudyTypesCompanion studyType) async {
    await into(studyTypes).insert(studyType);
    return studyType.id.value;
  }

  Future<void> deleteSubject(String id) async {
    await (delete(subjects)..where((s) => s.id.equals(id))).go();
  }

  Future<void> deleteStudyType(String id) async {
    await (delete(studyTypes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSubjectOrder(String id, int newOrder) async {
    await (update(subjects)..where((s) => s.id.equals(id)))
        .write(SubjectsCompanion(sortOrder: Value(newOrder)));
  }

  /// 切换科目隐藏状态
  Future<void> updateSubjectVisibility(String id, bool isHidden) async {
    await (update(subjects)..where((s) => s.id.equals(id)))
        .write(SubjectsCompanion(isHidden: Value(isHidden)));
  }
}
