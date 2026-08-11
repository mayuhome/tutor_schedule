import 'package:drift/drift.dart';

import 'tables/students_table.dart';
import 'tables/course_records_table.dart';
import 'tables/schedules_table.dart';
import 'tables/progress_table.dart';
import 'tables/course_fees_table.dart';

// Conditional imports for platform-specific database implementations
import 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Students,
  CourseRecords,
  Schedules,
  ProgressEntries,
  CourseFees,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(courseRecords, courseRecords.notes);
          }
          if (from < 3) {
            await m.createTable(courseFees);
            await m.addColumn(courseRecords, courseRecords.fee);
          }
        },
      );
}
