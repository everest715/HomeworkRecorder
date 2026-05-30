import 'package:drift/drift.dart';

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
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
