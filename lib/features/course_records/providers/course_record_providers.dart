import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../data/course_record_repository.dart';
import '../data/models/course_record_model.dart';

final courseRecordRepositoryProvider = Provider<CourseRecordRepository>((ref) {
  final db = ref.read(databaseProvider);
  return CourseRecordRepository(db);
});

final courseRecordListProvider =
    StreamProvider<List<CourseRecordModel>>((ref) {
  final repo = ref.read(courseRecordRepositoryProvider);
  return repo.watchAllRecords();
});

final recordsByStudentProvider =
    StreamProvider.family<List<CourseRecordModel>, String>((ref, studentId) {
  final repo = ref.read(courseRecordRepositoryProvider);
  return repo.watchRecordsByStudent(studentId);
});
