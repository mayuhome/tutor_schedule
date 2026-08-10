// Native database implementation (for Android, iOS, Desktop)
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show File;

DatabaseConnection createDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tutor_schedule.db'));
    return DatabaseConnection(NativeDatabase.createInBackground(file));
  }));
}
