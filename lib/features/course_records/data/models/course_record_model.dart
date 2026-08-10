import '../../../../core/database/app_database.dart';

class CourseRecordModel {
  final String id;
  final String studentId;
  final String subject;
  final DateTime date;
  final int duration;
  final String content;
  final String? homework;
  final int rating;
  final String? summary;
  final List<String> attachments;
  final DateTime createdAt;

  const CourseRecordModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.date,
    required this.duration,
    required this.content,
    this.homework,
    this.rating = 3,
    this.summary,
    this.attachments = const [],
    required this.createdAt,
  });

  factory CourseRecordModel.fromDb(CourseRecord record) {
    return CourseRecordModel(
      id: record.id,
      studentId: record.studentId,
      subject: record.subject,
      date: record.date,
      duration: record.duration,
      content: record.content,
      homework: record.homework,
      rating: record.rating,
      summary: record.summary,
      attachments: [], // TODO: Parse from JSON
      createdAt: record.createdAt,
    );
  }

  String get durationText {
    final h = duration ~/ 60;
    final m = duration % 60;
    if (h > 0 && m > 0) return '${h}小时${m}分钟';
    if (h > 0) return '$h小时';
    return '$m分钟';
  }

  String get ratingText {
    return switch (rating) {
      1 => '很差',
      2 => '较差',
      3 => '一般',
      4 => '良好',
      5 => '优秀',
      _ => '未评',
    };
  }
}
