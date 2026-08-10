import 'package:drift/drift.dart';
import 'students_table.dart';

class ProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get subject => text().withLength(min: 1, max: 50)();
  TextColumn get topic => text()();
  IntColumn get masteryLevel => integer().withDefault(const Constant(3))(); // 1-5
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
