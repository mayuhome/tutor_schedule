import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/students_table.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students])
class StudentDao extends DatabaseAccessor<AppDatabase>
    with _$StudentDaoMixin {
  StudentDao(super.db);

  Future<List<Student>> getAllStudents() =>
      (select(students)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<Student>> watchAllStudents() =>
      (select(students)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<Student?> getStudentById(String id) =>
      (select(students)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<Student?> watchStudentById(String id) =>
      (select(students)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<List<Student>> searchStudents(String query) =>
      (select(students)
            ..where((t) =>
                t.name.like('%$query%') |
                t.grade.like('%$query%') |
                t.subjects.like('%$query%'))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<int> insertStudent(StudentsCompanion entry) =>
      into(students).insert(entry);

  Future<bool> updateStudent(StudentsCompanion entry) =>
      update(students).replace(entry);

  Future<int> deleteStudent(String id) =>
      (delete(students)..where((t) => t.id.equals(id))).go();

  Future<int> getStudentCount() async {
    final count = await customSelect(
      'SELECT COUNT(*) as cnt FROM students',
      readsFrom: {students},
    ).getSingle();
    return count.data['cnt'] as int;
  }
}
