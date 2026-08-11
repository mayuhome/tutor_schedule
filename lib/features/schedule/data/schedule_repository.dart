import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/schedule_dao.dart';
import 'models/schedule_model.dart';

class ScheduleRepository {
  final ScheduleDao _dao;

  ScheduleRepository(AppDatabase db) : _dao = ScheduleDao(db);

  Future<List<ScheduleModel>> getAllSchedules() async =>
      (await _dao.getAllSchedules()).map(ScheduleModel.fromDb).toList();

  Stream<List<ScheduleModel>> watchAllSchedules() =>
      _dao.watchAllSchedules().map(
          (l) => l.map(ScheduleModel.fromDb).toList());

  /// 获取所有课程（包括已取消的）
  Stream<List<ScheduleModel>> watchAllSchedulesIncludingInactive() =>
      _dao.watchAllSchedulesIncludingInactive().map(
          (l) => l.map(ScheduleModel.fromDb).toList());

  Future<List<ScheduleModel>> getTodaySchedules() async =>
      (await _dao.getTodaySchedules()).map(ScheduleModel.fromDb).toList();

  Future<List<ScheduleModel>> getSchedulesByDay(int dayOfWeek) async =>
      (await _dao.getSchedulesByDay(dayOfWeek)).map(ScheduleModel.fromDb).toList();

  Stream<List<ScheduleModel>> watchSchedulesByDay(int dayOfWeek) =>
      _dao.watchSchedulesByDay(dayOfWeek).map(
          (l) => l.map(ScheduleModel.fromDb).toList());

  Future<ScheduleModel?> getScheduleById(String id) async {
    final s = await _dao.getScheduleById(id);
    return s != null ? ScheduleModel.fromDb(s) : null;
  }

  Future<List<ScheduleModel>> getSchedulesByGroup(String groupId) async =>
      (await _dao.getSchedulesByGroup(groupId)).map(ScheduleModel.fromDb).toList();

  Future<String> addSchedule(ScheduleModel schedule) async {
    final id = schedule.id.isNotEmpty ? schedule.id : const Uuid().v4();
    await _dao.insertSchedule(
      SchedulesCompanion.insert(
        id: id,
        studentId: schedule.studentId,
        subject: schedule.subject,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        dayOfWeek: Value(schedule.dayOfWeek),
        repeatRule: Value(schedule.repeatRule),
        repeatEndDate: Value(schedule.repeatEndDate),
        location: Value(schedule.location),
        isActive: Value(schedule.isActive),
        reminderMinutes: Value(schedule.reminderMinutes),
        calendarEventId: Value(schedule.calendarEventId),
        scheduleGroupId: Value(schedule.scheduleGroupId),
        biweeklyOffset: Value(schedule.biweeklyOffset),
        cancelledDates: Value(schedule.cancelledDates),
      ),
    );
    return id;
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _dao.updateSchedule(
      SchedulesCompanion(
        id: Value(schedule.id),
        studentId: Value(schedule.studentId),
        subject: Value(schedule.subject),
        dayOfWeek: Value(schedule.dayOfWeek),
        startTime: Value(schedule.startTime),
        endTime: Value(schedule.endTime),
        repeatRule: Value(schedule.repeatRule),
        repeatEndDate: Value(schedule.repeatEndDate),
        location: Value(schedule.location),
        isActive: Value(schedule.isActive),
        reminderMinutes: Value(schedule.reminderMinutes),
        calendarEventId: Value(schedule.calendarEventId),
        scheduleGroupId: Value(schedule.scheduleGroupId),
        biweeklyOffset: Value(schedule.biweeklyOffset),
        cancelledDates: Value(schedule.cancelledDates),
      ),
    );
  }

  Future<void> deleteSchedule(String id) => _dao.deleteSchedule(id);
  Future<void> deleteSchedulesByGroup(String groupId) => _dao.deleteSchedulesByGroup(groupId);

  Future<List<ScheduleModel>> getConflictingSchedules(
    int dayOfWeek, DateTime start, DateTime end, {String? excludeId}) async =>
      (await _dao.getConflictingSchedules(dayOfWeek, start, end, excludeId: excludeId))
          .map(ScheduleModel.fromDb).toList();
}
