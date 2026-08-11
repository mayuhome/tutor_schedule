import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/course_fee_dao.dart';
import 'models/course_fee_model.dart';

class CourseFeeRepository {
  final CourseFeeDao _dao;

  CourseFeeRepository(AppDatabase db) : _dao = CourseFeeDao(db);

  Future<List<CourseFeeModel>> getAllFees() async {
    final fees = await _dao.getAllFees();
    return fees.map(CourseFeeModel.fromDb).toList();
  }

  Future<List<CourseFeeModel>> getFeesByStudent(String studentId) async {
    final fees = await _dao.getFeesByStudent(studentId);
    return fees.map(CourseFeeModel.fromDb).toList();
  }

  Future<CourseFeeModel?> getFeeByStudentAndSubject(
      String studentId, String subject) async {
    final fee = await _dao.getFeeByStudentAndSubject(studentId, subject);
    return fee != null ? CourseFeeModel.fromDb(fee) : null;
  }

  Future<String> addFee(CourseFeeModel fee) async {
    final id = fee.id.isNotEmpty ? fee.id : const Uuid().v4();
    await _dao.insertFee(
      CourseFeesCompanion.insert(
        id: id,
        studentId: fee.studentId,
        subject: fee.subject,
        feePerHour: fee.feePerHour,
      ),
    );
    return id;
  }

  Future<void> updateFee(CourseFeeModel fee) async {
    await _dao.updateFee(
      CourseFeesCompanion(
        id: Value(fee.id),
        studentId: Value(fee.studentId),
        subject: Value(fee.subject),
        feePerHour: Value(fee.feePerHour),
      ),
    );
  }

  Future<void> deleteFee(String id) => _dao.deleteFee(id);

  Future<void> deleteFeesByStudent(String studentId) =>
      _dao.deleteFeesByStudent(studentId);
}
