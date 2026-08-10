import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/schedule_dao.dart';
import '../../../core/database/daos/course_record_dao.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../core/extensions/datetime_extensions.dart';

// Mock data for web demo
List<Schedule> _getMockTodaySchedules() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    Schedule(
      id: 'mock-1',
      studentId: 'student-1',
      subject: '数学',
      dayOfWeek: now.weekday,
      startTime: today.add(const Duration(hours: 9)),
      endTime: today.add(const Duration(hours: 11)),
      repeatRule: 'weekly',
      location: '学生家',
      isActive: true,
      reminderMinutes: 30,
      createdAt: now,
    ),
    Schedule(
      id: 'mock-2',
      studentId: 'student-2',
      subject: '英语',
      dayOfWeek: now.weekday,
      startTime: today.add(const Duration(hours: 14)),
      endTime: today.add(const Duration(hours: 16)),
      repeatRule: 'weekly',
      location: '咖啡厅',
      isActive: true,
      reminderMinutes: 30,
      createdAt: now,
    ),
    Schedule(
      id: 'mock-3',
      studentId: 'student-3',
      subject: '物理',
      dayOfWeek: now.weekday,
      startTime: today.add(const Duration(hours: 16, minutes: 30)),
      endTime: today.add(const Duration(hours: 18, minutes: 30)),
      repeatRule: 'weekly',
      location: '线上',
      isActive: true,
      reminderMinutes: 30,
      createdAt: now,
    ),
  ];
}

WeeklyStats _getMockWeeklyStats() {
  return const WeeklyStats(
    totalHours: 12.5,
    studentCount: 4,
    courseCount: 8,
  );
}

final todayCoursesProvider = FutureProvider<List<Schedule>>((ref) async {
  try {
    final db = ref.read(databaseProvider);
    final dao = ScheduleDao(db);
    return await dao.getTodaySchedules();
  } catch (e) {
    if (kIsWeb) {
      return _getMockTodaySchedules();
    }
    rethrow;
  }
});

final todayCourseCountProvider = Provider<int>((ref) {
  final courses = ref.watch(todayCoursesProvider);
  return courses.whenOrNull(data: (data) => data.length) ?? 0;
});

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  try {
    final db = ref.read(databaseProvider);
    final recordDao = CourseRecordDao(db);
    final studentDao = StudentDao(db);
    final scheduleDao = ScheduleDao(db);

    final now = DateTime.now();
    final startOfWeek = now.startOfWeek;
    final endOfWeek = now.endOfWeek;

    final totalMinutes =
        await recordDao.getTotalDurationByDateRange(startOfWeek, endOfWeek);
    final studentCount = await studentDao.getStudentCount();
    final allSchedules = await scheduleDao.getAllSchedules();

    return WeeklyStats(
      totalHours: totalMinutes / 60.0,
      studentCount: studentCount,
      courseCount: allSchedules.length,
    );
  } catch (e) {
    if (kIsWeb) {
      return _getMockWeeklyStats();
    }
    rethrow;
  }
});

class WeeklyStats {
  final double totalHours;
  final int studentCount;
  final int courseCount;

  const WeeklyStats({
    required this.totalHours,
    required this.studentCount,
    required this.courseCount,
  });
}

final recentRecordsProvider = FutureProvider((ref) async {
  try {
    final db = ref.read(databaseProvider);
    final dao = CourseRecordDao(db);
    return await dao.getAllRecords();
  } catch (e) {
    if (kIsWeb) {
      return <dynamic>[];
    }
    rethrow;
  }
});
