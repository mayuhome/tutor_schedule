import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/course_records_table.dart';

part 'course_record_dao.g.dart';

@DriftAccessor(tables: [CourseRecords])
class CourseRecordDao extends DatabaseAccessor<AppDatabase>
    with _$CourseRecordDaoMixin {
  CourseRecordDao(super.db);

  Future<List<CourseRecord>> getAllRecords() =>
      (select(courseRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<CourseRecord>> watchAllRecords() =>
      (select(courseRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<List<CourseRecord>> getRecordsByStudent(String studentId) =>
      (select(courseRecords)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<CourseRecord>> watchRecordsByStudent(String studentId) =>
      (select(courseRecords)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<List<CourseRecord>> getRecordsByDateRange(
      DateTime start, DateTime end) =>
      (select(courseRecords)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Future<List<CourseRecord>> getRecordsBySubject(String subject) =>
      (select(courseRecords)
            ..where((t) => t.subject.equals(subject))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<CourseRecord?> getRecordById(String id) =>
      (select(courseRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertRecord(CourseRecordsCompanion entry) =>
      into(courseRecords).insert(entry);

  Future<bool> updateRecord(CourseRecordsCompanion entry) =>
      update(courseRecords).replace(entry);

  Future<int> deleteRecord(String id) =>
      (delete(courseRecords)..where((t) => t.id.equals(id))).go();

  Future<int> getTotalDurationByDateRange(
      DateTime start, DateTime end) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(duration), 0) as total FROM course_records WHERE date >= ? AND date <= ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {courseRecords},
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<Map<String, int>> getSubjectDistribution(
      DateTime start, DateTime end) async {
    final results = await customSelect(
      'SELECT subject, SUM(duration) as total FROM course_records WHERE date >= ? AND date <= ? GROUP BY subject',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {courseRecords},
    ).get();
    return {for (var r in results) r.data['subject'] as String: r.data['total'] as int};
  }
}
