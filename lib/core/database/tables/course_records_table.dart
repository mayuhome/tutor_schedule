import 'package:drift/drift.dart';
import 'students_table.dart';

class CourseRecords extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get subject => text().withLength(min: 1, max: 50)();
  DateTimeColumn get date => dateTime()();
  IntColumn get duration => integer()(); // 分钟
  TextColumn get content => text()();
  TextColumn get homework => text().nullable()();
  IntColumn get rating => integer().withDefault(const Constant(3))(); // 1-5
  TextColumn get summary => text().nullable()();
  TextColumn get attachments => text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
