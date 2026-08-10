import '../../../../core/database/app_database.dart';

class ScheduleModel {
  final String id;
  final String studentId;
  final String subject;
  final int? dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;
  final String repeatRule;
  final DateTime? repeatEndDate;
  final String? location;
  final bool isActive;
  final int reminderMinutes;
  final DateTime createdAt;

  const ScheduleModel({
    required this.id,
    required this.studentId,
    required this.subject,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.repeatRule = 'none',
    this.repeatEndDate,
    this.location,
    this.isActive = true,
    this.reminderMinutes = 30,
    required this.createdAt,
  });

  factory ScheduleModel.fromDb(Schedule schedule) {
    return ScheduleModel(
      id: schedule.id,
      studentId: schedule.studentId,
      subject: schedule.subject,
      dayOfWeek: schedule.dayOfWeek,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      repeatRule: schedule.repeatRule,
      repeatEndDate: schedule.repeatEndDate,
      location: schedule.location,
      isActive: schedule.isActive,
      reminderMinutes: schedule.reminderMinutes,
      createdAt: schedule.createdAt,
    );
  }

  Duration get duration => endTime.difference(startTime);

  String get timeRange {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String get dayName {
    if (dayOfWeek == null) return '单次';
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[dayOfWeek! - 1];
  }

  String get repeatRuleName {
    return switch (repeatRule) {
      'weekly' => '每周',
      'biweekly' => '每两周',
      'custom' => '自定义',
      _ => '不重复',
    };
  }

  ScheduleModel copyWith({
    String? studentId,
    String? subject,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    String? repeatRule,
    DateTime? repeatEndDate,
    String? location,
    bool? isActive,
    int? reminderMinutes,
  }) {
    return ScheduleModel(
      id: id,
      studentId: studentId ?? this.studentId,
      subject: subject ?? this.subject,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt,
    );
  }
}
