import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../data/course_fee_repository.dart';
import '../data/models/course_fee_model.dart';

final courseFeeRepositoryProvider = Provider<CourseFeeRepository>((ref) {
  final db = ref.read(databaseProvider);
  return CourseFeeRepository(db);
});

final feesByStudentProvider =
    FutureProvider.family<List<CourseFeeModel>, String>((ref, studentId) {
  final repo = ref.read(courseFeeRepositoryProvider);
  return repo.getFeesByStudent(studentId);
});
