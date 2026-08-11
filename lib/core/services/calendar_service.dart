import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  Future<bool> hasPermissions() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  Future<List<Calendar>> getCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (result.isSuccess) return result.data ?? [];
    return [];
  }

  Future<Calendar?> getDefaultCalendar() async {
    final calendars = await getCalendars();
    for (final cal in calendars) {
      if (cal.isReadOnly == false) return cal;
    }
    return calendars.isNotEmpty ? calendars.first : null;
  }

  Future<String?> createEvent({
    required String calendarId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    int reminderMinutes = 30,
    String? repeatRule,
    DateTime? repeatEndDate,
  }) async {
    tz.initializeTimeZones();
    final startTZ = tz.TZDateTime.from(startTime, tz.local);
    final endTZ = tz.TZDateTime.from(endTime, tz.local);

    final event = Event(
      calendarId,
      title: title,
      start: startTZ,
      end: endTZ,
      description: description,
      location: location,
      reminders: [Reminder(minutes: reminderMinutes)],
    );

    if (repeatRule != null && repeatRule != 'none') {
      event.recurrenceRule = _buildRecurrenceRule(
        repeatRule,
        repeatEndDate: repeatEndDate,
      );
    }

    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null) return null;
    if (result.isSuccess && result.data != null) return result.data;
    return null;
  }

  Future<String?> updateEvent({
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    int reminderMinutes = 30,
    String? repeatRule,
    DateTime? repeatEndDate,
  }) async {
    tz.initializeTimeZones();
    final startTZ = tz.TZDateTime.from(startTime, tz.local);
    final endTZ = tz.TZDateTime.from(endTime, tz.local);

    final event = Event(
      calendarId,
      title: title,
      start: startTZ,
      end: endTZ,
      description: description,
      location: location,
      eventId: eventId,
      reminders: [Reminder(minutes: reminderMinutes)],
    );

    if (repeatRule != null && repeatRule != 'none') {
      event.recurrenceRule = _buildRecurrenceRule(
        repeatRule,
        repeatEndDate: repeatEndDate,
      );
    }

    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null) return null;
    if (result.isSuccess && result.data != null) return result.data;
    return null;
  }

  Future<bool> deleteEvent(String calendarId, String eventId) async {
    final result = await _plugin.deleteEvent(calendarId, eventId);
    return result.isSuccess;
  }

  RecurrenceRule? _buildRecurrenceRule(
    String repeatRule, {
    DateTime? repeatEndDate,
  }) {
    switch (repeatRule) {
      case 'weekly':
        return RecurrenceRule(
          RecurrenceFrequency.Weekly,
          interval: 1,
          endDate: repeatEndDate != null
              ? tz.TZDateTime.from(repeatEndDate, tz.local)
              : null,
        );
      case 'biweekly':
        return RecurrenceRule(
          RecurrenceFrequency.Weekly,
          interval: 2,
          endDate: repeatEndDate != null
              ? tz.TZDateTime.from(repeatEndDate, tz.local)
              : null,
        );
      default:
        return null;
    }
  }

  static DateTime getNextOccurrence(int dayOfWeek, int hour, int minute) {
    final now = DateTime.now();
    int daysUntil = dayOfWeek - now.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final todayStart = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayStart.isBefore(now)) daysUntil = 7;
    }
    final date = now.add(Duration(days: daysUntil));
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
