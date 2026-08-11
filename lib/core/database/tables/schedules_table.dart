import 'package:drift/drift.dart';
import 'students_table.dart';

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get subject => text().withLength(min: 1, max: 50)();
  IntColumn get dayOfWeek => integer().nullable()(); // 1-7 (周一到周日)
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get repeatRule => text().withDefault(const Constant('none'))(); // none, weekly, biweekly, custom
  DateTimeColumn get repeatEndDate => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get reminderMinutes => integer().withDefault(const Constant(30))();
  TextColumn get calendarEventId => text().nullable()(); // 系统日历事件ID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
