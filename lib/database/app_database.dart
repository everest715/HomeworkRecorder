import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables.dart';
import 'daos/records_dao.dart';
import 'daos/subjects_dao.dart';
import 'daos/stats_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Subjects,
  StudyTypes,
  StudyRecords,
  CompletionRatings,
], daos: [
  RecordsDao,
  SubjectsDao,
  StatsDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertPresetSubjects();
        await _insertPresetStudyTypes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(subjects, subjects.isHidden);
        }
      },
    );
  }

  Future<void> _insertPresetSubjects() async {
    final presets = [
      SubjectsCompanion.insert(id: 's1', name: '语文', icon: '📖', color: '#FFA726'),
      SubjectsCompanion.insert(id: 's2', name: '数学', icon: '📐', color: '#E94560'),
      SubjectsCompanion.insert(id: 's3', name: '英语', icon: '🔤', color: '#AB47BC'),
      SubjectsCompanion.insert(id: 's4', name: '物理', icon: '⚡', color: '#4FC3F7'),
      SubjectsCompanion.insert(id: 's5', name: '化学', icon: '🧪', color: '#66BB6A'),
      SubjectsCompanion.insert(id: 's6', name: '生物', icon: '🌱', color: '#8BC34A'),
      SubjectsCompanion.insert(id: 's7', name: '历史', icon: '🏛️', color: '#8D6E63'),
      SubjectsCompanion.insert(id: 's8', name: '地理', icon: '🌍', color: '#26A69A'),
      SubjectsCompanion.insert(id: 's9', name: '政治', icon: '📜', color: '#78909C'),
    ];
    await batch((b) => b.insertAll(subjects, presets));
  }

  Future<void> _insertPresetStudyTypes() async {
    final presets = [
      StudyTypesCompanion.insert(id: 't1', name: '练习卷', sortOrder: const Value(0)),
      StudyTypesCompanion.insert(id: 't2', name: '作业本', sortOrder: const Value(1)),
      StudyTypesCompanion.insert(id: 't3', name: '作文', sortOrder: const Value(2)),
      StudyTypesCompanion.insert(id: 't4', name: '朗读', sortOrder: const Value(3)),
      StudyTypesCompanion.insert(id: 't5', name: '背诵', sortOrder: const Value(4)),
      StudyTypesCompanion.insert(id: 't6', name: '预习', sortOrder: const Value(5)),
      StudyTypesCompanion.insert(id: 't7', name: '复习', sortOrder: const Value(6)),
      StudyTypesCompanion.insert(id: 't8', name: '笔记', sortOrder: const Value(7)),
    ];
    await batch((b) => b.insertAll(studyTypes, presets));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'homework_recorder.db'));
    return NativeDatabase.createInBackground(file);
  });
}
