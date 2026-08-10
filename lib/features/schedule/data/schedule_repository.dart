import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/schedule_dao.dart';
import 'models/schedule_model.dart';

class ScheduleRepository {
  final ScheduleDao _dao;

  ScheduleRepository(AppDatabase db) : _dao = ScheduleDao(db);

  Future<List<ScheduleModel>> getAllSchedules() async {
    final schedules = await _dao.getAllSchedules();
    return schedules.map(ScheduleModel.fromDb).toList();
  }

  Stream<List<ScheduleModel>> watchAllSchedules() {
    return _dao.watchAllSchedules().map(
          (schedules) => schedules.map(ScheduleModel.fromDb).toList(),
        );
  }

  Future<List<ScheduleModel>> getTodaySchedules() async {
    final schedules = await _dao.getTodaySchedules();
    return schedules.map(ScheduleModel.fromDb).toList();
  }

  Future<List<ScheduleModel>> getSchedulesByDay(int dayOfWeek) async {
    final schedules = await _dao.getSchedulesByDay(dayOfWeek);
    return schedules.map(ScheduleModel.fromDb).toList();
  }

  Stream<List<ScheduleModel>> watchSchedulesByDay(int dayOfWeek) {
    return _dao.watchSchedulesByDay(dayOfWeek).map(
          (schedules) => schedules.map(ScheduleModel.fromDb).toList(),
        );
  }

  Future<ScheduleModel?> getScheduleById(String id) async {
    final schedule = await _dao.getScheduleById(id);
    return schedule != null ? ScheduleModel.fromDb(schedule) : null;
  }

  Future<String> addSchedule(ScheduleModel schedule) async {
    final id = const Uuid().v4();
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
      ),
    );
  }

  Future<void> deleteSchedule(String id) async {
    await _dao.deleteSchedule(id);
  }

  Future<List<ScheduleModel>> getConflictingSchedules(
    int dayOfWeek,
    DateTime start,
    DateTime end, {
    String? excludeId,
  }) async {
    final schedules = await _dao.getConflictingSchedules(
      dayOfWeek, start, end,
      excludeId: excludeId,
    );
    return schedules.map(ScheduleModel.fromDb).toList();
  }
}
