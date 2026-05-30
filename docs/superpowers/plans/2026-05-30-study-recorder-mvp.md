# Study Recorder MVP 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现学习记录器 MVP，包含计时器、学习记录 CRUD、完成情况评分、统计图表四大核心功能

**Architecture:** Flutter + Riverpod 状态管理 + Drift (SQLite) 本地数据库 + GoRouter 路由。数据层由 Drift DAO 提供，Riverpod Provider 桥接 UI 与数据层。UI 采用 Material 3 主题，4 Tab 底部导航。

**Tech Stack:** Flutter 3.44, Riverpod 2.x, Drift, fl_chart, GoRouter, SharedPreferences, uuid

---

## Phase 1: 项目脚手架与数据层

### Task 1: 初始化 Flutter 项目与 Git 仓库

**Files:**
- Create: 整个 Flutter 项目结构

- [ ] **Step 1: 初始化 Git 仓库并创建 Flutter 项目**

```bash
cd E:\SelfProjects\HomeworkRecorder
git init
C:\flutter-sdk\bin\flutter.bat create --org com.homeworkrecorder --project-name homework_recorder --platforms android,ios,windows .
```

- [ ] **Step 2: 验证项目创建成功**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

Expected: No issues found

- [ ] **Step 3: 添加核心依赖**

```bash
C:\flutter-sdk\bin\flutter.bat add riverpod_annotation flutter_riverpod drift sqlite3_flutter_libs fl_chart go_router shared_preferences uuid path_provider path
C:\flutter-sdk\bin\flutter.bat add --dev build_runner drift_dev riverpod_generator custom_lint riverpod_lint
```

- [ ] **Step 4: 创建 .gitignore 补充项**

在 `.gitignore` 末尾追加:

```
# Drift generated
*.g.dart
*.freezed.dart

# Build runner
.dart_tool/
build/

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Codely
.codely-cli/
.superpowers/
```

- [ ] **Step 5: 提交初始项目**

```bash
git add -A
git commit -m "feat: 初始化 Flutter 项目与核心依赖"
```

---

### Task 2: 数据模型定义 — Drift 表与 Dart 模型

**Files:**
- Create: `lib/database/tables.dart`
- Create: `lib/models/study_record.dart`
- Create: `lib/models/completion_rating.dart`
- Create: `lib/models/subject.dart`
- Create: `lib/models/study_type.dart`
- Create: `lib/models/user_settings.dart`
- Create: `lib/models/timer_state.dart`

- [ ] **Step 1: 创建 Drift 表定义**

Create `lib/database/tables.dart`:

```dart
import 'package:drift/drift.dart';

/// 科目表
class Subjects extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()(); // emoji 或图标标识
  TextColumn get color => text()(); // hex color string
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 学习类型表
class StudyTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 学习记录表
class StudyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get typeId => text().references(StudyTypes, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get timerMode => text()(); // 'countup' or 'countdown'
  IntColumn get targetSeconds => integer().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 完成情况评分表 — 与学习记录 1:1
class CompletionRatings extends Table {
  TextColumn get recordId => text().references(StudyRecords, #id)();
  IntColumn get accuracy => intCheckConstraint(1, 5)();
  IntColumn get focus => intCheckConstraint(1, 5)();
  IntColumn get speed => intCheckConstraint(1, 5)();
  IntColumn get difficulty => intCheckConstraint(1, 5)();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {recordId};
}
```

Note: Drift 不原生支持 `intCheckConstraint`，需改用 `integer().check(value.isBetween(1, 5))`。修正版本：

```dart
import 'package:drift/drift.dart';

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudyTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get typeId => text().references(StudyTypes, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get timerMode => text()();
  IntColumn get targetSeconds => integer().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CompletionRatings extends Table {
  TextColumn get recordId => text().references(StudyRecords, #id)();
  IntColumn get accuracy => integer().check(accuracy.isBetweenValues(1, 5))();
  IntColumn get focus => integer().check(focus.isBetweenValues(1, 5))();
  IntColumn get speed => integer().check(speed.isBetweenValues(1, 5))();
  IntColumn get difficulty => integer().check(difficulty.isBetweenValues(1, 5))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {recordId};
}
```

- [ ] **Step 2: 创建 Dart 枚举与纯数据模型**

Create `lib/models/timer_state.dart`:

```dart
/// 计时器模式
enum TimerMode { countup, countdown }

/// 计时器运行状态
enum TimerStatus { idle, running, paused }

/// 计时器完整状态
class TimerState {
  final TimerMode mode;
  final TimerStatus status;
  final int elapsedSeconds;
  final int? targetSeconds;
  final String? subjectId;
  final String? typeId;

  const TimerState({
    this.mode = TimerMode.countup,
    this.status = TimerStatus.idle,
    this.elapsedSeconds = 0,
    this.targetSeconds,
    this.subjectId,
    this.typeId,
  });

  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? elapsedSeconds,
    int? targetSeconds,
    String? subjectId,
    String? typeId,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      subjectId: subjectId ?? this.subjectId,
      typeId: typeId ?? this.typeId,
    );
  }
}
```

Create `lib/models/user_settings.dart`:

```dart
/// 用户角色
enum UserRole { parent, child }

/// 主题模式
enum ThemeMode { light, dark, system }

/// 用户设置
class UserSettings {
  final UserRole currentRole;
  final TimerMode defaultTimerMode;
  final int defaultCountdownMinutes;
  final bool cloudSyncEnabled;
  final ThemeMode themeMode;

  const UserSettings({
    this.currentRole = UserRole.parent,
    this.defaultTimerMode = TimerMode.countup,
    this.defaultCountdownMinutes = 30,
    this.cloudSyncEnabled = false,
    this.themeMode = ThemeMode.system,
  });

  UserSettings copyWith({
    UserRole? currentRole,
    TimerMode? defaultTimerMode,
    int? defaultCountdownMinutes,
    bool? cloudSyncEnabled,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      currentRole: currentRole ?? this.currentRole,
      defaultTimerMode: defaultTimerMode ?? this.defaultTimerMode,
      defaultCountdownMinutes:
          defaultCountdownMinutes ?? this.defaultCountdownMinutes,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      themeMode: themeMode ?? this.themeMode,
    });
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "feat: 定义 Drift 表结构与 Dart 数据模型"
```

---

### Task 3: Drift 数据库定义与 DAO

**Files:**
- Create: `lib/database/app_database.dart`
- Create: `lib/database/daos/records_dao.dart`
- Create: `lib/database/daos/subjects_dao.dart`
- Create: `lib/database/daos/stats_dao.dart`

- [ ] **Step 1: 创建 AppDatabase 主文件**

Create `lib/database/app_database.dart`:

```dart
import 'package:drift/drift.dart';
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // 插入预设科目
        await _insertPresetSubjects();
        // 插入预设类型
        await _insertPresetStudyTypes();
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
```

- [ ] **Step 2: 创建 RecordsDao**

Create `lib/database/daos/records_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'records_dao.g.dart';

@DriftAccessor(tables: [StudyRecords, CompletionRatings])
class RecordsDao extends DatabaseAccessor<AppDatabase>
    with _$RecordsDaoMixin {
  RecordsDao(super.db);

  /// 查询某日所有记录
  Future<List<StudyRecord>> getRecordsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  /// 查询某条记录的评分
  Future<CompletionRating?> getRatingForRecord(String recordId) {
    return (select(completionRatings)
          ..where((r) => r.recordId.equals(recordId)))
        .getSingleOrNull();
  }

  /// 插入学习记录
  Future<String> insertRecord(StudyRecordsCompanion record) async {
    await into(studyRecords).insert(record);
    return record.id.value;
  }

  /// 插入完成情况评分
  Future<void> insertRating(CompletionRatingsCompanion rating) async {
    await into(completionRatings).insert(rating);
  }

  /// 更新学习记录
  Future<void> updateRecord(StudyRecordsCompanion record) async {
    await (update(studyRecords)
          ..where((r) => r.id.equals(record.id.value)))
        .write(record);
  }

  /// 删除学习记录（级联删除评分）
  Future<void> deleteRecord(String recordId) async {
    await (delete(completionRatings)
          ..where((r) => r.recordId.equals(recordId)))
        .go();
    await (delete(studyRecords)..where((r) => r.id.equals(recordId))).go();
  }

  /// 获取日期范围内的记录
  Future<List<StudyRecord>> getRecordsInRange(
      DateTime start, DateTime end) {
    return (select(studyRecords)
          ..where((r) => r.date.isBiggerOrEqualValue(start))
          ..where((r) => r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .get();
  }
}
```

- [ ] **Step 3: 创建 SubjectsDao**

Create `lib/database/daos/subjects_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects, StudyTypes])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  /// 获取所有科目（按排序字段）
  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  /// 获取所有类型（按排序字段）
  Future<List<StudyType>> getAllStudyTypes() {
    return (select(studyTypes)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// 获取单个科目
  Future<Subject> getSubjectById(String id) {
    return (select(subjects)..where((s) => s.id.equals(id))).getSingle();
  }

  /// 获取单个类型
  Future<StudyType> getStudyTypeById(String id) {
    return (select(studyTypes)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 新增自定义科目
  Future<String> insertSubject(SubjectsCompanion subject) async {
    await into(subjects).insert(subject);
    return subject.id.value;
  }

  /// 新增自定义类型
  Future<String> insertStudyType(StudyTypesCompanion studyType) async {
    await into(studyTypes).insert(studyType);
    return studyType.id.value;
  }

  /// 删除自定义科目
  Future<void> deleteSubject(String id) async {
    await (delete(subjects)..where((s) => s.id.equals(id))).go();
  }

  /// 删除自定义类型
  Future<void> deleteStudyType(String id) async {
    await (delete(studyTypes)..where((t) => t.id.equals(id))).go();
  }

  /// 更新科目排序
  Future<void> updateSubjectOrder(String id, int newOrder) async {
    await (update(subjects)..where((s) => s.id.equals(id)))
        .write(SubjectsCompanion(sortOrder: Value(newOrder)));
  }
}
```

- [ ] **Step 4: 创建 StatsDao**

Create `lib/database/daos/stats_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'stats_dao.g.dart';

@DriftAccessor(tables: [StudyRecords, CompletionRatings, Subjects])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  /// 获取日期范围内的每日学习总时长
  /// 返回 List<{date, totalSeconds}>
  Future<List<DailyDuration>> getDailyDurations(DateTime start, DateTime end) {
    final query = selectOnly(studyRecords)
      ..addColumns([
        studyRecords.date,
        studyRecords.durationSeconds.sum()
      ])
      ..where(studyRecords.date.isBiggerOrEqualValue(start))
      ..where(studyRecords.date.isSmallerThanValue(end))
      ..groupBy([studyRecords.date]);

    return query.map((row) => DailyDuration(
          date: row.read(studyRecords.date)!,
          totalSeconds: row.read(studyRecords.durationSeconds.sum()) ?? 0,
        )).get();
  }

  /// 获取日期范围内各科目学习时长
  /// 返回 List<{subjectId, totalSeconds}>
  Future<List<SubjectDuration>> getSubjectDurations(
      DateTime start, DateTime end) {
    final query = selectOnly(studyRecords)
      ..addColumns([
        studyRecords.subjectId,
        studyRecords.durationSeconds.sum(),
      ])
      ..where(studyRecords.date.isBiggerOrEqualValue(start))
      ..where(studyRecords.date.isSmallerThanValue(end))
      ..groupBy([studyRecords.subjectId]);

    return query.map((row) => SubjectDuration(
          subjectId: row.read(studyRecords.subjectId)!,
          totalSeconds: row.read(studyRecords.durationSeconds.sum()) ?? 0,
        )).get();
  }

  /// 获取日期范围内的平均评分
  Future<List<AverageRatings>> getAverageRatings(
      DateTime start, DateTime end) async {
    final query = select(completionRatings).join([
      innerJoin(
          studyRecords, studyRecords.id.equalsExp(completionRatings.recordId)),
    ])
      ..where(studyRecords.date.isBiggerOrEqualValue(start))
      ..where(studyRecords.date.isSmallerThanValue(end));

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final avgAccuracy =
        rows.map((r) => r.readTable(completionRatings).accuracy).reduce((a, b) => a + b) /
            rows.length;
    final avgFocus =
        rows.map((r) => r.readTable(completionRatings).focus).reduce((a, b) => a + b) /
            rows.length;
    final avgSpeed =
        rows.map((r) => r.readTable(completionRatings).speed).reduce((a, b) => a + b) /
            rows.length;
    final avgDifficulty = rows
            .map((r) => r.readTable(completionRatings).difficulty)
            .reduce((a, b) => a + b) /
        rows.length;

    return [
      AverageRatings(
        avgAccuracy: avgAccuracy,
        avgFocus: avgFocus,
        avgSpeed: avgSpeed,
        avgDifficulty: avgDifficulty,
      )
    ];
  }

  /// 获取某日概览：总时长、完成数
  Future<DaySummary> getDaySummary(DateTime date) async {
    final records = await (select(studyRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(
                  DateTime(date.year, date.month, date.day))
              ..where((r) => r.date.isSmallerThanValue(
                  DateTime(date.year, date.month, date.day)
                      .add(const Duration(days: 1)))))
        .get();

    final totalSeconds =
        records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
    return DaySummary(
      totalSeconds: totalSeconds,
      recordCount: records.length,
    );
  }
}

/// 统计查询结果辅助类
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
```

- [ ] **Step 5: 运行 build_runner 生成代码**

```bash
C:\flutter-sdk\bin\flutter.bat pub run build_runner build --delete-conflicting-outputs
```

Expected: 生成 `app_database.g.dart`, `records_dao.g.dart`, `subjects_dao.g.dart`, `stats_dao.g.dart`

- [ ] **Step 6: 验证编译通过**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

Expected: No issues found

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "feat: 创建 Drift 数据库与 DAO 层"
```

---

## Phase 2: 状态管理与路由

### Task 4: Riverpod Providers

**Files:**
- Create: `lib/providers/database_provider.dart`
- Create: `lib/providers/records_provider.dart`
- Create: `lib/providers/timer_provider.dart`
- Create: `lib/providers/stats_provider.dart`
- Create: `lib/providers/settings_provider.dart`

- [ ] **Step 1: 创建 Database Provider**

Create `lib/providers/database_provider.dart`:

```dart
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
```

- [ ] **Step 2: 创建 Records Provider**

Create `lib/providers/records_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

/// 今日日期
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// 今日学习记录列表
final todayRecordsProvider =
    FutureProvider.autoDispose<List<StudyRecord>>((ref) async {
  final dao = ref.watch(recordsDaoProvider);
  final today = ref.watch(todayProvider);
  return dao.getRecordsForDate(today);
});

/// 指定记录的评分
final ratingForRecordProvider =
    FutureProvider.autoDispose.family<CompletionRating?, String>(
  (ref, recordId) async {
    final dao = ref.watch(recordsDaoProvider);
    return dao.getRatingForRecord(recordId);
  },
);

/// 新增记录后刷新
final addRecordProvider =
    FutureProvider.autoDispose.family<void, StudyRecordsCompanion>(
  (ref, record) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.insertRecord(record);
    ref.invalidate(todayRecordsProvider);
  },
);

/// 新增评分后刷新
final addRatingProvider =
    FutureProvider.autoDispose.family<void, CompletionRatingsCompanion>(
  (ref, rating) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.insertRating(rating);
    ref.invalidate(todayRecordsProvider);
  },
);

/// 删除记录后刷新
final deleteRecordProvider =
    FutureProvider.autoDispose.family<void, String>(
  (ref, recordId) async {
    final dao = ref.watch(recordsDaoProvider);
    await dao.deleteRecord(recordId);
    ref.invalidate(todayRecordsProvider);
  },
);

/// 日期范围内的记录
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
```

- [ ] **Step 3: 创建 Timer Provider (Notifier)**

Create `lib/providers/timer_provider.dart`:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const TimerState();
  }

  void setSubject(String subjectId) {
    state = state.copyWith(subjectId: subjectId);
  }

  void setType(String typeId) {
    state = state.copyWith(typeId: typeId);
  }

  void setMode(TimerMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setTargetSeconds(int seconds) {
    state = state.copyWith(targetSeconds: seconds);
  }

  void start() {
    state = state.copyWith(status: TimerStatus.running);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      if (state.mode == TimerMode.countdown &&
          state.targetSeconds != null &&
          state.elapsedSeconds >= state.targetSeconds!) {
        _timer?.cancel();
        state = state.copyWith(status: TimerStatus.idle);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() {
    start();
  }

  void stop() {
    _timer?.cancel();
    // 保持 elapsedSeconds 不变，状态改 idle
    state = state.copyWith(status: TimerStatus.idle);
  }

  void reset() {
    _timer?.cancel();
    state = const TimerState();
  }

  /// 重置所有状态到初始
  void fullReset() {
    _timer?.cancel();
    state = const TimerState();
  }
}
```

- [ ] **Step 4: 创建 Stats Provider**

Create `lib/providers/stats_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/stats_dao.dart';
import 'database_provider.dart';

/// 统计视图范围
enum StatsViewRange { week, month, semester }

/// 当前选中的统计范围
final statsViewRangeProvider =
    StateProvider<StatsViewRange>((ref) => StatsViewRange.week);

/// 当前选中的周/月起始日
final statsStartDateProvider =
    StateProvider<DateTime>((ref) => _startOfCurrentWeek());

DateTime _startOfCurrentWeek() {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
}

/// 每日学习时长
final dailyDurationsProvider =
    FutureProvider.autoDispose<List<DailyDuration>>((ref) async {
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getDailyDurations(start, end);
});

/// 各科目学习时长
final subjectDurationsProvider =
    FutureProvider.autoDispose<List<SubjectDuration>>((ref) async {
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getSubjectDurations(start, end);
});

/// 平均评分
final averageRatingsProvider =
    FutureProvider.autoDispose<List<AverageRatings>>((ref) async {
  final dao = ref.watch(statsDaoProvider);
  final start = ref.watch(statsStartDateProvider);
  final range = ref.watch(statsViewRangeProvider);
  final end = _endOfRange(start, range);
  return dao.getAverageRatings(start, end);
});

/// 日概览
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
```

- [ ] **Step 5: 创建 Settings Provider**

Create `lib/providers/settings_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../models/timer_state.dart';

const _keyRole = 'user_role';
const _keyTimerMode = 'default_timer_mode';
const _keyCountdownMinutes = 'default_countdown_minutes';
const _keyCloudSync = 'cloud_sync_enabled';
const _keyThemeMode = 'theme_mode';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      currentRole: UserRole.values[prefs.getInt(_keyRole) ?? 0],
      defaultTimerMode:
          TimerMode.values[prefs.getInt(_keyTimerMode) ?? 0],
      defaultCountdownMinutes:
          prefs.getInt(_keyCountdownMinutes) ?? 30,
      cloudSyncEnabled: prefs.getBool(_keyCloudSync) ?? false,
      themeMode: ThemeMode.values[prefs.getInt(_keyThemeMode) ?? 2],
    );
  }

  Future<void> setRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRole, role.index);
    state = AsyncData(state.value!.copyWith(currentRole: role));
  }

  Future<void> setDefaultTimerMode(TimerMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimerMode, mode.index);
    state = AsyncData(state.value!.copyWith(defaultTimerMode: mode));
  }

  Future<void> setDefaultCountdownMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCountdownMinutes, minutes);
    state =
        AsyncData(state.value!.copyWith(defaultCountdownMinutes: minutes));
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCloudSync, enabled);
    state = AsyncData(state.value!.copyWith(cloudSyncEnabled: enabled));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }
}
```

- [ ] **Step 6: 验证编译**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "feat: 创建 Riverpod Providers 层"
```

---

### Task 5: GoRouter 路由与 App 入口

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: 创建 App 入口 (GoRouter + 4 Tab)**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/records/records_page.dart';
import 'pages/timer/timer_page.dart';
import 'pages/stats/stats_page.dart';
import 'pages/settings/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/records',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                builder: (context, state) => const RecordsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                builder: (context, state) => const TimerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class StudyRecorderApp extends ConsumerWidget {
  const StudyRecorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: '学习记录器',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4FC3F7),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: '记录'),
          NavigationDestination(icon: Icon(Icons.timer), label: '计时'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '统计'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 修改 main.dart**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StudyRecorderApp()));
}
```

- [ ] **Step 3: 创建页面占位文件**

Create `lib/pages/records/records_page.dart`:

```dart
import 'package:flutter/material.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('记录页面')),
    );
  }
}
```

Create `lib/pages/timer/timer_page.dart`:

```dart
import 'package:flutter/material.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('计时页面')),
    );
  }
}
```

Create `lib/pages/stats/stats_page.dart`:

```dart
import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('统计页面')),
    );
  }
}
```

Create `lib/pages/settings/settings_page.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('设置页面')),
    );
  }
}
```

- [ ] **Step 4: 验证编译并运行**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
C:\flutter-sdk\bin\flutter.bat run -d windows
```

Expected: 应用启动，底部4个Tab可切换

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat: 搭建 GoRouter 路由与底部导航"
```

---

## Phase 3: 计时器页面

### Task 6: 计时器页面完整实现

**Files:**
- Modify: `lib/pages/timer/timer_page.dart`
- Create: `lib/widgets/timer_display.dart`

- [ ] **Step 1: 创建 TimerDisplay 组件**

Create `lib/widgets/timer_display.dart`:

```dart
import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int elapsedSeconds;
  final int? targetSeconds;
  final bool isCountdown;

  const TimerDisplay({
    super.key,
    required this.elapsedSeconds,
    this.targetSeconds,
    this.isCountdown = false,
  });

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = isCountdown && targetSeconds != null
        ? (targetSeconds! - elapsedSeconds).clamp(0, targetSeconds!)
        : elapsedSeconds;
    final progress = isCountdown && targetSeconds != null && targetSeconds! > 0
        ? elapsedSeconds / targetSeconds!
        : 0.0;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCountdown && targetSeconds != null)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            )
          else
            CircularProgressIndicator(
              value: null,
              strokeWidth: 8,
              color: Theme.of(context).colorScheme.primary,
            ),
          Text(
            _formatDuration(displaySeconds),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 实现完整计时器页面**

Replace `lib/pages/timer/timer_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';
import '../../widgets/timer_display.dart';
import 'completion_sheet.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final subjectsAsync = ref.watch(subjectsDaoProvider).getAllSubjects();
    final typesAsync = ref.watch(subjectsDaoProvider).getAllStudyTypes();

    return Scaffold(
      appBar: AppBar(title: const Text('计时')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 科目选择
          FutureBuilder(
            future: subjectsAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final subjects = snapshot.data!;
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: subjects.map((s) {
                    final selected = timerState.subjectId == s.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text('${s.icon} ${s.name}'),
                        onSelected: (_) => ref
                            .read(timerProvider.notifier)
                            .setSubject(s.id),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // 类型选择
          FutureBuilder(
            future: typesAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final types = snapshot.data!;
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: types.map((t) {
                    final selected = timerState.typeId == t.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text(t.name),
                        onSelected: (_) => ref
                            .read(timerProvider.notifier)
                            .setType(t.id),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 模式切换
          SegmentedButton<TimerMode>(
            segments: const [
              ButtonSegment(value: TimerMode.countup, label: Text('正计时')),
              ButtonSegment(value: TimerMode.countdown, label: Text('倒计时')),
            ],
            selected: {timerState.mode},
            onSelectionChanged: (modes) =>
                ref.read(timerProvider.notifier).setMode(modes.first),
          ),
          if (timerState.mode == TimerMode.countdown) ...[
            const SizedBox(height: 8),
            Text(
              '目标: ${timerState.targetSeconds != null ? '${timerState.targetSeconds! ~/ 60} 分钟' : '未设置'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: (timerState.targetSeconds ?? 1800) / 60,
              min: 5,
              max: 120,
              divisions: 23,
              label: '${((timerState.targetSeconds ?? 1800) ~/ 60)} 分钟',
              onChanged: (v) => ref
                  .read(timerProvider.notifier)
                  .setTargetSeconds((v * 60).round()),
            ),
          ],
          const SizedBox(height: 32),
          // 计时显示
          TimerDisplay(
            elapsedSeconds: timerState.elapsedSeconds,
            targetSeconds: timerState.targetSeconds,
            isCountdown: timerState.mode == TimerMode.countdown,
          ),
          const SizedBox(height: 32),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timerState.status == TimerStatus.idle)
                FilledButton.icon(
                  onPressed: timerState.subjectId != null
                      ? () =>
                          ref.read(timerProvider.notifier).start()
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                ),
              if (timerState.status == TimerStatus.running) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(timerProvider.notifier).pause(),
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () =>
                      _stopAndSave(context, ref, timerState),
                  icon: const Icon(Icons.stop),
                  label: const Text('结束'),
                ),
              ],
              if (timerState.status == TimerStatus.paused) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(timerProvider.notifier).resume(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () =>
                      _stopAndSave(context, ref, timerState),
                  icon: const Icon(Icons.stop),
                  label: const Text('结束'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _stopAndSave(
      BuildContext context, WidgetRef ref, TimerState timerState) {
    ref.read(timerProvider.notifier).stop();
    if (timerState.subjectId != null && timerState.elapsedSeconds > 0) {
      final record = StudyRecordsCompanion.insert(
        id: const Uuid().v4(),
        subjectId: timerState.subjectId!,
        typeId: timerState.typeId ?? 't1',
        date: DateTime.now(),
        durationSeconds: timerState.elapsedSeconds,
        timerMode: timerState.mode.name,
        targetSeconds: Value(timerState.targetSeconds),
      );
      // 保存记录并弹出评分表单
      ref.read(recordsDaoProvider).insertRecord(record).then((recordId) {
        ref.read(timerProvider.notifier).fullReset();
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CompletionSheet(recordId: recordId),
          );
        }
      });
    } else {
      ref.read(timerProvider.notifier).fullReset();
    }
  }
}
```

- [ ] **Step 3: 创建完成情况录入弹窗**

Create `lib/pages/timer/completion_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/records_provider.dart';

class CompletionSheet extends ConsumerStatefulWidget {
  final String recordId;

  const CompletionSheet({super.key, required this.recordId});

  @override
  ConsumerState<CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends ConsumerState<CompletionSheet> {
  double _accuracy = 3;
  double _focus = 3;
  double _speed = 3;
  double _difficulty = 3;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('完成情况',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSlider('🎯 正确率', _accuracy, (v) => setState(() => _accuracy = v)),
          _buildSlider('🧠 专注度', _focus, (v) => setState(() => _focus = v)),
          _buildSlider('⚡ 完成速度', _speed, (v) => setState(() => _speed = v)),
          _buildSlider('💪 难易度', _difficulty, (v) => setState(() => _difficulty = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（选填）',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 24, child: Text('${value.round()}')),
      ],
    );
  }

  void _save() {
    final rating = CompletionRatingsCompanion.insert(
      recordId: widget.recordId,
      accuracy: _accuracy.round(),
      focus: _focus.round(),
      speed: _speed.round(),
      difficulty: _difficulty.round(),
      note: Value(_noteController.text.isEmpty ? null : _noteController.text),
    );
    ref.read(recordsDaoProvider).insertRating(rating).then((_) {
      ref.invalidate(todayRecordsProvider);
      Navigator.of(context).pop();
    });
  }
}
```

- [ ] **Step 4: 验证编译**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat: 实现计时器页面与完成情况录入"
```

---

## Phase 4: 记录列表页面

### Task 7: 记录列表页面完整实现

**Files:**
- Modify: `lib/pages/records/records_page.dart`
- Create: `lib/pages/records/record_detail_page.dart`
- Create: `lib/utils/formatters.dart`

- [ ] **Step 1: 创建工具函数**

Create `lib/utils/formatters.dart`:

```dart
/// 格式化秒数为 "Xh Xm" 或 "Xm"
String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}

/// 格式化秒数为 "MM:SS"
String formatDurationShort(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// 格式化日期为 "M月d日"
String formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// 格式化日期为 "HH:MM"
String formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 2: 实现记录列表页**

Replace `lib/pages/records/records_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/records_provider.dart';
import '../../providers/database_provider.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 切换到计时 Tab
          DefaultTabController.of(context).animateTo(1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<_RecordItem>> _loadRecordsWithDetails(
    List<StudyRecord> records,
    dynamic subjectsDao,
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
```

- [ ] **Step 3: 创建记录详情页**

Create `lib/pages/records/record_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/records_provider.dart';
import '../../providers/database_provider.dart';
import '../../utils/formatters.dart';

class RecordDetailPage extends ConsumerWidget {
  final StudyRecord record;

  const RecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(ratingForRecordProvider(record.id));
    final subjectAsync = ref.read(subjectsDaoProvider).getSubjectById(record.subjectId);
    final typeAsync = ref.read(subjectsDaoProvider).getStudyTypeById(record.typeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条学习记录吗？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(recordsDaoProvider).deleteRecord(record.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([subjectAsync, typeAsync]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subject = snapshot.data![0] as Subject;
          final studyType = snapshot.data![1] as StudyType;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.icon} ${subject.name}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('类型: ${studyType.name}'),
                      Text('日期: ${formatDate(record.date)} ${formatTime(record.date)}'),
                      Text('时长: ${formatDuration(record.durationSeconds)}'),
                      Text('模式: ${record.timerMode == 'countup' ? '正计时' : '倒计时'}'),
                      if (record.targetSeconds != null)
                        Text('目标时长: ${formatDuration(record.targetSeconds!)}'),
                      if (record.note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('备注: ${record.note}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('完成情况', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ratingAsync.when(
                data: (rating) {
                  if (rating == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('未录入完成情况'),
                      ),
                    );
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _RatingRow(label: '🎯 正确率', value: rating.accuracy),
                          _RatingRow(label: '🧠 专注度', value: rating.focus),
                          _RatingRow(label: '⚡ 完成速度', value: rating.speed),
                          _RatingRow(label: '💪 难易度', value: rating.difficulty),
                          if (rating.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('备注: ${rating.note}'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('加载评分失败'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int value;

  const _RatingRow({required this.label, required this.value});

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
          SizedBox(width: 24, child: Text('$value/5')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 验证编译**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat: 实现记录列表页与详情页"
```

---

## Phase 5: 统计页面

### Task 8: 统计页面完整实现

**Files:**
- Modify: `lib/pages/stats/stats_page.dart`

- [ ] **Step 1: 实现统计页面**

Replace `lib/pages/stats/stats_page.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
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
                  // 每日学习时长柱状图
                  Text('学习时长',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _DailyBarChart(),
                  const SizedBox(height: 24),
                  // 科目时间分布饼图
                  Text('科目分布',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _SubjectPieChart(),
                  const SizedBox(height: 24),
                  // 平均评分
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
                barGroups: spots,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}m'),
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
```

- [ ] **Step 2: 验证编译**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "feat: 实现统计页面（周/月/学期视图+图表）"
```

---

## Phase 6: 设置页面

### Task 9: 设置页面完整实现

**Files:**
- Modify: `lib/pages/settings/settings_page.dart`

- [ ] **Step 1: 实现设置页面**

Replace `lib/pages/settings/settings_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/timer_state.dart';
import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // 角色切换
            _SectionTitle('角色'),
            ListTile(
              title: const Text('当前角色'),
              subtitle: Text(settings.currentRole == UserRole.parent
                  ? '家长'
                  : '孩子'),
              trailing: SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(value: UserRole.parent, label: Text('家长')),
                  ButtonSegment(value: UserRole.child, label: Text('孩子')),
                ],
                selected: {settings.currentRole},
                onSelectionChanged: (roles) => ref
                    .read(settingsProvider.notifier)
                    .setRole(roles.first),
              ),
            ),

            const Divider(),

            // 计时器默认设置
            _SectionTitle('计时器'),
            ListTile(
              title: const Text('默认计时模式'),
              trailing: SegmentedButton<TimerMode>(
                segments: const [
                  ButtonSegment(value: TimerMode.countup, label: Text('正计时')),
                  ButtonSegment(
                      value: TimerMode.countdown, label: Text('倒计时')),
                ],
                selected: {settings.defaultTimerMode},
                onSelectionChanged: (modes) => ref
                    .read(settingsProvider.notifier)
                    .setDefaultTimerMode(modes.first),
              ),
            ),
            if (settings.defaultTimerMode == TimerMode.countdown)
              ListTile(
                title: const Text('默认倒计时分钟数'),
                trailing: Text('${settings.defaultCountdownMinutes} 分钟'),
                subtitle: Slider(
                  value: settings.defaultCountdownMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${settings.defaultCountdownMinutes} 分钟',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setDefaultCountdownMinutes(v.round()),
                ),
              ),

            const Divider(),

            // 主题
            _SectionTitle('外观'),
            ListTile(
              title: const Text('主题模式'),
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                  ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (modes) => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(modes.first),
              ),
            ),

            const Divider(),

            // 科目管理
            _SectionTitle('科目管理'),
            _SubjectManagementList(),

            const Divider(),

            // 类型管理
            _SectionTitle('类型管理'),
            _StudyTypeManagementList(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载设置失败: $e')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SubjectManagementList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(subjectsDaoProvider).getAllSubjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final subjects = snapshot.data!;
        return Column(
          children: [
            ...subjects.map((s) => ListTile(
                  leading: Text(s.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(s.name),
                  trailing: s.isCustom
                      ? IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            await ref
                                .read(subjectsDaoProvider)
                                .deleteSubject(s.id);
                          },
                        )
                      : null,
                )),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加自定义科目'),
              onTap: () => _showAddSubjectDialog(context, ref),
            ),
          ],
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedIcon = '📚';
    String selectedColor = '#2196F3';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加科目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '科目名称'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(subjectsDaoProvider).insertSubject(
                      SubjectsCompanion.insert(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        icon: selectedIcon,
                        color: selectedColor,
                        isCustom: const Value(true),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _StudyTypeManagementList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(subjectsDaoProvider).getAllStudyTypes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final types = snapshot.data!;
        return Column(
          children: [
            ...types.map((t) => ListTile(
                  title: Text(t.name),
                  trailing: t.isCustom
                      ? IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            await ref
                                .read(subjectsDaoProvider)
                                .deleteStudyType(t.id);
                          },
                        )
                      : null,
                )),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加自定义类型'),
              onTap: () => _showAddTypeDialog(context, ref),
            ),
          ],
        );
      },
    );
  }

  void _showAddTypeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加类型'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '类型名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(subjectsDaoProvider).insertStudyType(
                      StudyTypesCompanion.insert(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        isCustom: const Value(true),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "feat: 实现设置页面（角色/计时器/主题/科目类型管理）"
```

---

## Phase 7: 集成与最终验证

### Task 10: 全局状态刷新与集成修复

**Files:**
- Modify: `lib/app.dart` — 主题跟随设置
- Modify: `lib/pages/timer/timer_page.dart` — 完成评分后刷新记录
- Various: 修复编译问题

- [ ] **Step 1: 让 App 主题跟随设置**

在 `lib/app.dart` 的 `StudyRecorderApp.build` 中，将 `themeData` 改为根据 `settingsProvider` 切换 `themeMode`：

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(goRouterProvider);
  final settingsAsync = ref.watch(settingsProvider);
  final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

  return MaterialApp.router(
    title: '学习记录器',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF4FC3F7),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF4FC3F7),
      useMaterial3: true,
      brightness: Brightness.dark,
    ),
    themeMode: themeMode == ThemeMode.light
        ? ThemeMode.light
        : themeMode == ThemeMode.dark
            ? ThemeMode.dark
            : ThemeMode.system,
    routerConfig: router,
  );
}
```

- [ ] **Step 2: 运行完整分析**

```bash
C:\flutter-sdk\bin\flutter.bat analyze
```

Expected: No issues found

- [ ] **Step 3: 在 Windows 桌面运行验证完整流程**

```bash
C:\flutter-sdk\bin\flutter.bat run -d windows
```

验证以下流程：
1. 底部4 Tab 可切换
2. 计时页选择科目+类型 → 开始计时 → 暂停/继续 → 结束
3. 结束后弹出评分弹窗 → 滑块打分 → 保存
4. 记录页显示今日记录 → 点击查看详情
5. 统计页显示柱状图/饼图/评分
6. 设置页角色切换、主题切换、科目/类型管理

- [ ] **Step 4: 提交**

```bash
git add -A
git commit -m "feat: 集成完成，主题跟随设置，全局刷新修复"
```

---

## 自审检查

### Spec 覆盖检查

| 需求 | 对应 Task |
|------|-----------|
| Flutter 项目初始化 | Task 1 |
| 数据模型 (5个实体) | Task 2, 3 |
| 计时器 (正/倒计时、暂停/继续/停止) | Task 6 |
| 完成情况录入 (4维评分) | Task 6 (CompletionSheet) |
| 记录列表 + 概览卡片 | Task 7 |
| 记录详情 + 删除 | Task 7 |
| 统计 (周/月/学期 + 柱状/饼/评分) | Task 8 |
| 设置 (角色/计时器/主题/科目管理/类型管理) | Task 9 |
| 预设科目 (9个) + 预设类型 (8个) | Task 3 |
| 4 Tab 底部导航 | Task 5 |
| Material 3 主题 | Task 5, 10 |

### Placeholder 扫描

无 TBD/TODO/待实现占位符。

### 类型一致性

所有 Provider 引用的 DAO 方法名、模型字段名、表名在各 Task 间保持一致。
