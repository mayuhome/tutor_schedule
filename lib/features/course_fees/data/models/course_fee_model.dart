import '../../../../core/database/app_database.dart';

class CourseFeeModel {
  final String id;
  final String studentId;
  final String subject;
  final double feePerHour;
  final DateTime createdAt;

  const CourseFeeModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.feePerHour,
    required this.createdAt,
  });

  factory CourseFeeModel.fromDb(CourseFee fee) {
    return CourseFeeModel(
      id: fee.id,
      studentId: fee.studentId,
      subject: fee.subject,
      feePerHour: fee.feePerHour,
      createdAt: fee.createdAt,
    );
  }

  double calculateFee(int durationMinutes) {
    return feePerHour * durationMinutes / 60.0;
  }

  String get feeText => '¥${feePerHour.toStringAsFixed(0)}/小时';
}
