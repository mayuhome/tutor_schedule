import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/students_table.dart';
import 'tables/course_records_table.dart';
import 'tables/schedules_table.dart';
import 'tables/progress_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Students,
  CourseRecords,
  Schedules,
  ProgressEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tutor_schedule.db'));
    return NativeDatabase.createInBackground(file);
  });
}
