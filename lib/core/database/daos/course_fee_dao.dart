import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/course_fees_table.dart';

part 'course_fee_dao.g.dart';

@DriftAccessor(tables: [CourseFees])
class CourseFeeDao extends DatabaseAccessor<AppDatabase>
    with _$CourseFeeDaoMixin {
  CourseFeeDao(super.db);

  Future<List<CourseFee>> getAllFees() =>
      (select(courseFees)..orderBy([(t) => OrderingTerm.asc(t.subject)]))
          .get();

  Future<List<CourseFee>> getFeesByStudent(String studentId) =>
      (select(courseFees)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.asc(t.subject)]))
          .get();

  Future<CourseFee?> getFeeByStudentAndSubject(
          String studentId, String subject) =>
      (select(courseFees)
            ..where((t) =>
                t.studentId.equals(studentId) &
                t.subject.equals(subject)))
          .getSingleOrNull();

  Future<int> insertFee(CourseFeesCompanion entry) =>
      into(courseFees).insert(entry,
          onConflict: DoUpdate((old) => entry));

  Future<bool> updateFee(CourseFeesCompanion entry) =>
      update(courseFees).replace(entry);

  Future<int> deleteFee(String id) =>
      (delete(courseFees)..where((t) => t.id.equals(id))).go();

  Future<int> deleteFeesByStudent(String studentId) =>
      (delete(courseFees)..where((t) => t.studentId.equals(studentId))).go();
}
