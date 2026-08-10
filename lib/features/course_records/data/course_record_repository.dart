import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/course_record_dao.dart';
import 'models/course_record_model.dart';

class CourseRecordRepository {
  final CourseRecordDao _dao;

  CourseRecordRepository(AppDatabase db) : _dao = CourseRecordDao(db);

  Future<List<CourseRecordModel>> getAllRecords() async {
    final records = await _dao.getAllRecords();
    return records.map(CourseRecordModel.fromDb).toList();
  }

  Stream<List<CourseRecordModel>> watchAllRecords() {
    return _dao.watchAllRecords().map(
          (records) => records.map(CourseRecordModel.fromDb).toList(),
        );
  }

  Future<List<CourseRecordModel>> getRecordsByStudent(String studentId) async {
    final records = await _dao.getRecordsByStudent(studentId);
    return records.map(CourseRecordModel.fromDb).toList();
  }

  Stream<List<CourseRecordModel>> watchRecordsByStudent(String studentId) {
    return _dao.watchRecordsByStudent(studentId).map(
          (records) => records.map(CourseRecordModel.fromDb).toList(),
        );
  }

  Future<List<CourseRecordModel>> getRecordsByDateRange(
      DateTime start, DateTime end) async {
    final records = await _dao.getRecordsByDateRange(start, end);
    return records.map(CourseRecordModel.fromDb).toList();
  }

  Future<String> addRecord(CourseRecordModel record) async {
    final id = const Uuid().v4();
    await _dao.insertRecord(
      CourseRecordsCompanion.insert(
        id: id,
        studentId: record.studentId,
        subject: record.subject,
        date: record.date,
        duration: record.duration,
        content: record.content,
        homework: Value(record.homework),
        rating: Value(record.rating),
        summary: Value(record.summary),
      ),
    );
    return id;
  }

  Future<void> updateRecord(CourseRecordModel record) async {
    await _dao.updateRecord(
      CourseRecordsCompanion(
        id: Value(record.id),
        studentId: Value(record.studentId),
        subject: Value(record.subject),
        date: Value(record.date),
        duration: Value(record.duration),
        content: Value(record.content),
        homework: Value(record.homework),
        rating: Value(record.rating),
        summary: Value(record.summary),
      ),
    );
  }

  Future<void> deleteRecord(String id) async {
    await _dao.deleteRecord(id);
  }

  Future<int> getTotalDuration(DateTime start, DateTime end) {
    return _dao.getTotalDurationByDateRange(start, end);
  }

  Future<Map<String, int>> getSubjectDistribution(
      DateTime start, DateTime end) {
    return _dao.getSubjectDistribution(start, end);
  }
}
