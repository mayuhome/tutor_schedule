extension DateTimeExtensions on DateTime {
  String get weekdayName {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday - 1];
  }

  String get shortWeekdayName {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[weekday - 1];
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String get relativeDay {
    if (isToday) return '今天';
    if (isTomorrow) return '明天';
    if (isYesterday) return '昨天';
    return '$month月$day日';
  }

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get dateString {
    return '$year年$month月$day日';
  }

  String get shortDateString {
    return '$month/$day';
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  DateTime get startOfMonth => DateTime(year, month, 1);

  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
}
