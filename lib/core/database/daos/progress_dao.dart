import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/progress_table.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [ProgressEntries])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<List<ProgressEntry>> getProgressByStudent(String studentId) =>
      (select(progressEntries)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Stream<List<ProgressEntry>> watchProgressByStudent(String studentId) =>
      (select(progressEntries)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<ProgressEntry>> getProgressBySubject(
      String studentId, String subject) =>
      (select(progressEntries)
            ..where((t) =>
                t.studentId.equals(studentId) &
                t.subject.equals(subject))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<int> insertProgress(ProgressEntriesCompanion entry) =>
      into(progressEntries).insert(entry);

  Future<bool> updateProgress(ProgressEntriesCompanion entry) =>
      update(progressEntries).replace(entry);

  Future<int> deleteProgress(String id) =>
      (delete(progressEntries)..where((t) => t.id.equals(id))).go();
}
