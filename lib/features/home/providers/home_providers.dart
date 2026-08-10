import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/database/daos/schedule_dao.dart';
import '../../../core/database/daos/course_record_dao.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../core/extensions/datetime_extensions.dart';

final todayCoursesProvider = FutureProvider<List<dynamic>>((ref) async {
  final db = ref.read(databaseProvider);
  final dao = ScheduleDao(db);
  return dao.getTodaySchedules();
});

final todayCourseCountProvider = Provider<int>((ref) {
  final courses = ref.watch(todayCoursesProvider);
  return courses.whenOrNull(data: (data) => data.length) ?? 0;
});

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final db = ref.read(databaseProvider);
  final recordDao = CourseRecordDao(db);
  final studentDao = StudentDao(db);

  final now = DateTime.now();
  final startOfWeek = now.startOfWeek;
  final endOfWeek = now.endOfWeek;

  final totalMinutes =
      await recordDao.getTotalDurationByDateRange(startOfWeek, endOfWeek);
  final studentCount = await studentDao.getStudentCount();

  return WeeklyStats(
    totalHours: totalMinutes / 60.0,
    studentCount: studentCount,
    courseCount: 0, // Will be calculated from schedules
  );
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
  final db = ref.read(databaseProvider);
  final dao = CourseRecordDao(db);
  return dao.getAllRecords();
});
