import 'package:drift/drift.dart';

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get grade => text().withLength(min: 1, max: 20)();
  TextColumn get school => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get parentPhone => text().nullable()();
  TextColumn get subjects => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get notes => text().nullable()();
  TextColumn get avatarColor => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
