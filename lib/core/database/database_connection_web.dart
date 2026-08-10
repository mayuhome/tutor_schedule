// Web database implementation (for Web platform)
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection createDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    return DatabaseConnection(WebDatabase('tutor_schedule'));
  }));
}
