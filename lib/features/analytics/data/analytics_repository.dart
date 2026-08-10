import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/database/daos/course_record_dao.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../core/extensions/datetime_extensions.dart';

class AnalyticsData {
  final double totalHours;
  final int totalCourses;
  final int totalStudents;
  final Map<String, int> subjectDistribution;
  final double estimatedIncome;

  const AnalyticsData({
    required this.totalHours,
    required this.totalCourses,
    required this.totalStudents,
    required this.subjectDistribution,
    required this.estimatedIncome,
  });
}

class DailyStats {
  final DateTime date;
  final int duration;

  const DailyStats({required this.date, required this.duration});
}

final selectedPeriodProvider = StateProvider<String>((ref) => 'week');

final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final db = ref.read(databaseProvider);
  final recordDao = CourseRecordDao(db);
  final studentDao = StudentDao(db);
  final period = ref.watch(selectedPeriodProvider);

  final now = DateTime.now();
  DateTime start;
  DateTime end = now;

  switch (period) {
    case 'week':
      start = now.startOfWeek;
      break;
    case 'month':
      start = now.startOfMonth;
      break;
    case 'year':
      start = DateTime(now.year, 1, 1);
      break;
    default:
      start = now.startOfWeek;
  }

  final totalMinutes =
      await recordDao.getTotalDurationByDateRange(start, end);
  final subjectDist =
      await recordDao.getSubjectDistribution(start, end);
  final studentCount = await studentDao.getStudentCount();

  return AnalyticsData(
    totalHours: totalMinutes / 60.0,
    totalCourses: 0, // TODO: Count from records
    totalStudents: studentCount,
    subjectDistribution: subjectDist,
    estimatedIncome: (totalMinutes / 60.0) * 200, // Default rate
  );
});

final dailyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final db = ref.read(databaseProvider);
  final dao = CourseRecordDao(db);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));

  final records = await dao.getRecordsByDateRange(start, now);

  // Group by date
  final Map<String, int> dailyMinutes = {};
  for (var record in records) {
    final dateKey =
        '${record.date.year}-${record.date.month}-${record.date.day}';
    dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + record.duration;
  }

  return List.generate(7, (index) {
    final date = now.subtract(Duration(days: 6 - index));
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return DailyStats(
      date: date,
      duration: dailyMinutes[dateKey] ?? 0,
    );
  });
});
