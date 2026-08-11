import 'package:drift/drift.dart';
import 'students_table.dart';

class CourseFees extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get subject => text().withLength(min: 1, max: 50)();
  RealColumn get feePerHour => real()(); // 每小时费用
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {studentId, subject},
      ];
}
