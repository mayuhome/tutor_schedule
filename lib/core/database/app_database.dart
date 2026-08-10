import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables/students_table.dart';
import 'tables/course_records_table.dart';
import 'tables/schedules_table.dart';
import 'tables/progress_table.dart';

// Conditional imports for platform-specific database implementations
import 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Students,
  CourseRecords,
  Schedules,
  ProgressEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );
}
