import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../data/student_repository.dart';
import '../data/models/student_model.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final db = ref.read(databaseProvider);
  return StudentRepository(db);
});

final studentListProvider = StreamProvider<List<StudentModel>>((ref) {
  final repo = ref.read(studentRepositoryProvider);
  return repo.watchAllStudents();
});

final studentDetailProvider =
    StreamProvider.family<StudentModel?, String>((ref, id) {
  final repo = ref.read(studentRepositoryProvider);
  return repo.watchStudentById(id);
});

final studentSearchProvider =
    StateProvider<String>((ref) => '');

final filteredStudentsProvider = Provider<AsyncValue<List<StudentModel>>>((ref) {
  final searchQuery = ref.watch(studentSearchProvider);
  final studentsAsync = ref.watch(studentListProvider);

  if (searchQuery.isEmpty) return studentsAsync;

  return studentsAsync.whenData((students) => students
      .where((s) =>
          s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.grade.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.subjects.any(
              (sub) => sub.toLowerCase().contains(searchQuery.toLowerCase())))
      .toList());
});
