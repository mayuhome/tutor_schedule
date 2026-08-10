import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/student_dao.dart';
import 'models/student_model.dart';

class StudentRepository {
  final StudentDao _dao;

  StudentRepository(AppDatabase db) : _dao = StudentDao(db);

  Future<List<StudentModel>> getAllStudents() async {
    final students = await _dao.getAllStudents();
    return students.map(StudentModel.fromDb).toList();
  }

  Stream<List<StudentModel>> watchAllStudents() {
    return _dao.watchAllStudents().map(
          (students) => students.map(StudentModel.fromDb).toList(),
        );
  }

  Future<StudentModel?> getStudentById(String id) async {
    final student = await _dao.getStudentById(id);
    return student != null ? StudentModel.fromDb(student) : null;
  }

  Stream<StudentModel?> watchStudentById(String id) {
    return _dao.watchStudentById(id).map(
          (student) => student != null ? StudentModel.fromDb(student) : null,
        );
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    final students = await _dao.searchStudents(query);
    return students.map(StudentModel.fromDb).toList();
  }

  Future<String> addStudent(StudentModel student) async {
    final id = const Uuid().v4();
    await _dao.insertStudent(
      StudentsCompanion.insert(
        id: id,
        name: student.name,
        grade: student.grade,
        school: Value(student.school),
        phone: Value(student.phone),
        parentPhone: Value(student.parentPhone),
        subjects: Value(student.subjects.toString()),
        tags: Value(student.tags.toString()),
        notes: Value(student.notes),
        avatarColor: Value(student.avatarColor),
      ),
    );
    return id;
  }

  Future<void> updateStudent(StudentModel student) async {
    await _dao.updateStudent(
      StudentsCompanion(
        id: Value(student.id),
        name: Value(student.name),
        grade: Value(student.grade),
        school: Value(student.school),
        phone: Value(student.phone),
        parentPhone: Value(student.parentPhone),
        subjects: Value(student.subjects.toString()),
        tags: Value(student.tags.toString()),
        notes: Value(student.notes),
        avatarColor: Value(student.avatarColor),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteStudent(String id) async {
    await _dao.deleteStudent(id);
  }

  Future<int> getStudentCount() => _dao.getStudentCount();
}
