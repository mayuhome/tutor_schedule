import 'dart:convert';
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
  final String? calendarEventId;
  final String? scheduleGroupId;
  final int biweeklyOffset; // 0=本周开始, 1=下周开始
  final String? cancelledDates; // JSON编码的已取消日期列表
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
    this.calendarEventId,
    this.scheduleGroupId,
    this.biweeklyOffset = 0,
    this.cancelledDates,
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
      calendarEventId: schedule.calendarEventId,
      scheduleGroupId: schedule.scheduleGroupId,
      biweeklyOffset: schedule.biweeklyOffset ?? 0,
      cancelledDates: schedule.cancelledDates,
      createdAt: schedule.createdAt,
    );
  }

  Duration get duration => endTime.difference(startTime);

  String get timeRange {
    final s = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final e = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$s - $e';
  }

  String get dayName {
    if (dayOfWeek == null) return '单次';
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[dayOfWeek! - 1];
  }

  String get repeatRuleName {
    return switch (repeatRule) {
      'weekly' => '每周',
      'biweekly' => biweeklyOffset == 0 ? '双周(本周起)' : '双周(下周起)',
      'custom' => '自定义',
      _ => '不重复',
    };
  }

  bool get isSyncedToCalendar => calendarEventId != null && calendarEventId!.isNotEmpty;
  bool get isInGroup => scheduleGroupId != null && scheduleGroupId!.isNotEmpty;

  // ---- 已取消日期管理 ----

  /// 解析已取消日期列表
  List<DateTime> get parsedCancelledDates {
    if (cancelledDates == null || cancelledDates!.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(cancelledDates!);
      return list.map((s) => DateTime.parse(s as String)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 检查指定日期是否已取消
  bool isCancelledOn(DateTime date) {
    final dates = parsedCancelledDates;
    return dates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  /// 取消指定日期，返回新的 ScheduleModel
  ScheduleModel cancelOnDate(DateTime date) {
    final dates = parsedCancelledDates;
    if (dates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day)) {
      return this; // 已经取消过了
    }
    dates.add(date);
    final newJson = jsonEncode(dates.map((d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toList());
    return copyWith(cancelledDates: newJson);
  }

  /// 恢复指定日期，返回新的 ScheduleModel
  ScheduleModel restoreOnDate(DateTime date) {
    final dates = parsedCancelledDates;
    dates.removeWhere((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
    final newJson = dates.isEmpty
        ? null
        : jsonEncode(dates.map((d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toList());
    return copyWith(cancelledDates: newJson);
  }

  /// 获取课程状态描述
  String get statusText {
    if (!isActive) return '已停用';
    final now = DateTime.now();
    if (repeatRule == 'none') {
      if (startTime.isBefore(now)) return '已完成';
      return '未开始';
    }
    if (repeatEndDate != null && repeatEndDate!.isBefore(now)) return '已结束';
    return '进行中';
  }

  /// 是否已结束（单次课程已过时间，或重复课程已过结束日期）
  bool get isCompleted {
    final now = DateTime.now();
    if (!isActive) return false;
    if (repeatRule == 'none') return startTime.isBefore(now);
    if (repeatEndDate != null) return repeatEndDate!.isBefore(now);
    return false;
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
    String? calendarEventId,
    String? scheduleGroupId,
    int? biweeklyOffset,
    String? cancelledDates,
    bool clearCancelledDates = false,
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
      calendarEventId: calendarEventId ?? this.calendarEventId,
      scheduleGroupId: scheduleGroupId ?? this.scheduleGroupId,
      biweeklyOffset: biweeklyOffset ?? this.biweeklyOffset,
      cancelledDates: clearCancelledDates
          ? null
          : (cancelledDates ?? this.cancelledDates),
      createdAt: createdAt,
    );
  }
}
