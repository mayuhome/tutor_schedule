import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/services/calendar_service.dart';
import '../data/schedule_repository.dart';
import '../data/models/schedule_model.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final db = ref.read(databaseProvider);
  return ScheduleRepository(db);
});

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final scheduleListProvider = StreamProvider<List<ScheduleModel>>((ref) {
  final repo = ref.read(scheduleRepositoryProvider);
  return repo.watchAllSchedules();
});

final todaySchedulesProvider = FutureProvider<List<ScheduleModel>>((ref) async {
  final repo = ref.read(scheduleRepositoryProvider);
  return repo.getTodaySchedules();
});

final selectedDayProvider = StateProvider<int>((ref) {
  return DateTime.now().weekday;
});

final schedulesByDayProvider =
    StreamProvider.family<List<ScheduleModel>, int>((ref, dayOfWeek) {
  final repo = ref.read(scheduleRepositoryProvider);
  return repo.watchSchedulesByDay(dayOfWeek);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
