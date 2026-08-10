import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/schedules_table.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [Schedules])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  Future<List<Schedule>> getAllSchedules() =>
      (select(schedules)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([
              (t) => OrderingTerm.asc(t.dayOfWeek),
              (t) => OrderingTerm.asc(t.startTime),
            ]))
          .get();

  Stream<List<Schedule>> watchAllSchedules() =>
      (select(schedules)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([
              (t) => OrderingTerm.asc(t.dayOfWeek),
              (t) => OrderingTerm.asc(t.startTime),
            ]))
          .watch();

  Future<List<Schedule>> getSchedulesByDay(int dayOfWeek) =>
      (select(schedules)
            ..where((t) =>
                t.dayOfWeek.equals(dayOfWeek) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  Stream<List<Schedule>> watchSchedulesByDay(int dayOfWeek) =>
      (select(schedules)
            ..where((t) =>
                t.dayOfWeek.equals(dayOfWeek) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  Future<List<Schedule>> getSchedulesByStudent(String studentId) =>
      (select(schedules)
            ..where((t) =>
                t.studentId.equals(studentId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  Future<Schedule?> getScheduleById(String id) =>
      (select(schedules)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertSchedule(SchedulesCompanion entry) =>
      into(schedules).insert(entry);

  Future<bool> updateSchedule(SchedulesCompanion entry) =>
      update(schedules).replace(entry);

  Future<int> deleteSchedule(String id) =>
      (delete(schedules)..where((t) => t.id.equals(id))).go();

  Future<List<Schedule>> getConflictingSchedules(
      int dayOfWeek, DateTime start, DateTime end,
      {String? excludeId}) async {
    final query = select(schedules)
      ..where((t) =>
          t.dayOfWeek.equals(dayOfWeek) &
          t.isActive.equals(true) &
          t.startTime.isSmallerThanValue(end) &
          t.endTime.isBiggerThanValue(start));
    if (excludeId != null) {
      query.where((t) => t.id.isNotValue(excludeId));
    }
    return query.get();
  }

  Future<List<Schedule>> getTodaySchedules() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    return (select(schedules)
          ..where((t) =>
              t.dayOfWeek.equals(dayOfWeek) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }
}
