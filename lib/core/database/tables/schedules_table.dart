import 'package:drift/drift.dart';
import 'students_table.dart';

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get subject => text().withLength(min: 1, max: 50)();
  IntColumn get dayOfWeek => integer().nullable()(); // 1-7 (周一到周日)
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get repeatRule => text().withDefault(const Constant('none'))();
  DateTimeColumn get repeatEndDate => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get reminderMinutes => integer().withDefault(const Constant(30))();
  TextColumn get calendarEventId => text().nullable()();
  TextColumn get scheduleGroupId => text().nullable()(); // 同一课程的多个时间段分组
  IntColumn get biweeklyOffset => integer().nullable().withDefault(const Constant(0))(); // 0=本周开始, 1=下周开始
  TextColumn get cancelledDates => text().nullable()(); // JSON编码的已取消日期列表, 如 ["2026-08-13","2026-08-27"]
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
