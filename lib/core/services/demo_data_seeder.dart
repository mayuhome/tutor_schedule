import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/tables/students_table.dart';
import '../database/tables/schedules_table.dart';
import '../database/tables/course_records_table.dart';

class DemoDataSeeder {
  final AppDatabase db;
  static const _uuid = Uuid();

  DemoDataSeeder(this.db);

  Future<void> seed() async {
    // 检查是否已有数据
    final studentCount = await (db.selectOnly(db.students)
          ..addColumns([db.students.id.count()]))
        .getSingle();
    final count = studentCount.read(db.students.id.count()) ?? 0;

    if (count > 0) {
      return; // 已有数据，跳过
    }

    // 创建学生
    final students = await _createStudents();

    // 创建课程安排
    await _createSchedules(students);

    // 创建课程记录
    await _createCourseRecords(students);
  }

  Future<List<Student>> _createStudents() async {
    final now = DateTime.now();
    final studentData = [
      StudentsCompanion(
        id: Value(_uuid.v4()),
        name: const Value('张小明'),
        grade: const Value('高二'),
        school: const Value('市第一中学'),
        phone: const Value('13800138001'),
        parentPhone: const Value('13900139001'),
        subjects: const Value('["数学", "物理"]'),
        tags: const Value('["重点培养", "理科"]'),
        avatarColor: const Value('#4CAF50'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      StudentsCompanion(
        id: Value(_uuid.v4()),
        name: const Value('李小红'),
        grade: const Value('初三'),
        school: const Value('实验中学'),
        phone: const Value('13800138002'),
        parentPhone: const Value('13900139002'),
        subjects: const Value('["英语", "语文"]'),
        tags: const Value('["文科", "冲刺中考"]'),
        avatarColor: const Value('#2196F3'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      StudentsCompanion(
        id: Value(_uuid.v4()),
        name: const Value('王小华'),
        grade: const Value('小学五年级'),
        school: const Value('阳光小学'),
        phone: const Value('13800138003'),
        parentPhone: const Value('13900139003'),
        subjects: const Value('["数学", "英语"]'),
        tags: const Value('["基础辅导"]'),
        avatarColor: const Value('#FF9800'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      StudentsCompanion(
        id: Value(_uuid.v4()),
        name: const Value('赵小刚'),
        grade: const Value('高三'),
        school: const Value('市第一中学'),
        phone: const Value('13800138004'),
        parentPhone: const Value('13900139004'),
        subjects: const Value('["数学", "物理", "化学"]'),
        tags: const Value('["高考冲刺", "理科"]'),
        avatarColor: const Value('#9C27B0'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    final students = <Student>[];
    for (final data in studentData) {
      await db.into(db.students).insert(data);
      students.add(Student(
        id: data.id.value,
        name: data.name.value,
        grade: data.grade.value,
        school: data.school.value,
        phone: data.phone.value,
        parentPhone: data.parentPhone.value,
        subjects: data.subjects.value,
        tags: data.tags.value,
        notes: data.notes.value,
        avatarColor: data.avatarColor.value,
        createdAt: data.createdAt.value,
        updatedAt: data.updatedAt.value,
      ));
    }
    return students;
  }

  Future<void> _createSchedules(List<Student> students) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday; // 1=周一, 7=周日

    // 创建今天的课程安排
    final scheduleData = [
      // 上午课程
      SchedulesCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[0].id),
        subject: const Value('数学'),
        dayOfWeek: Value(weekday),
        startTime: Value(today.add(const Duration(hours: 9, minutes: 0))),
        endTime: Value(today.add(const Duration(hours: 11, minutes: 0))),
        repeatRule: const Value('weekly'),
        location: const Value('学生家'),
        isActive: const Value(true),
        createdAt: Value(now),
      ),
      SchedulesCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[1].id),
        subject: const Value('英语'),
        dayOfWeek: Value(weekday),
        startTime: Value(today.add(const Duration(hours: 14, minutes: 0))),
        endTime: Value(today.add(const Duration(hours: 16, minutes: 0))),
        repeatRule: const Value('weekly'),
        location: const Value('咖啡厅'),
        isActive: const Value(true),
        createdAt: Value(now),
      ),
      SchedulesCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[2].id),
        subject: const Value('数学'),
        dayOfWeek: Value(weekday),
        startTime: Value(today.add(const Duration(hours: 16, minutes: 30))),
        endTime: Value(today.add(const Duration(hours: 18, minutes: 0))),
        repeatRule: const Value('weekly'),
        location: const Value('学生家'),
        isActive: const Value(true),
        createdAt: Value(now),
      ),
      // 晚上课程
      SchedulesCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[3].id),
        subject: const Value('物理'),
        dayOfWeek: Value(weekday),
        startTime: Value(today.add(const Duration(hours: 19, minutes: 0))),
        endTime: Value(today.add(const Duration(hours: 21, minutes: 0))),
        repeatRule: const Value('weekly'),
        location: const Value('线上'),
        isActive: const Value(true),
        createdAt: Value(now),
      ),
      // 其他日期的课程
      SchedulesCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[0].id),
        subject: const Value('物理'),
        dayOfWeek: Value(weekday == 7 ? 1 : weekday + 1), // 明天
        startTime: Value(today.add(const Duration(days: 1, hours: 10, minutes: 0))),
        endTime: Value(today.add(const Duration(days: 1, hours: 12, minutes: 0))),
        repeatRule: const Value('weekly'),
        location: const Value('图书馆'),
        isActive: const Value(true),
        createdAt: Value(now),
      ),
    ];

    for (final data in scheduleData) {
      await db.into(db.schedules).insert(data);
    }
  }

  Future<void> _createCourseRecords(List<Student> students) async {
    final now = DateTime.now();

    // 创建本周和上周的课程记录
    final records = [
      // 本周记录
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[0].id),
        subject: const Value('数学'),
        date: Value(now.subtract(const Duration(days: 1))),
        duration: const Value(120),
        content: const Value('讲解了导数的基本概念和求导法则，完成了5道练习题'),
        homework: const Value('完成课本P45-48的习题'),
        rating: const Value(4),
        createdAt: Value(now),
      ),
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[1].id),
        subject: const Value('英语'),
        date: Value(now.subtract(const Duration(days: 2))),
        duration: const Value(120),
        content: const Value('复习了定语从句，练习了阅读理解'),
        homework: const Value('背诵Unit5单词，完成阅读练习'),
        rating: const Value(5),
        createdAt: Value(now),
      ),
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[2].id),
        subject: const Value('数学'),
        date: Value(now.subtract(const Duration(days: 3))),
        duration: const Value(90),
        content: const Value('分数和小数的转换，混合运算练习'),
        homework: const Value('完成练习册第12页'),
        rating: const Value(4),
        createdAt: Value(now),
      ),
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[3].id),
        subject: const Value('物理'),
        date: Value(now.subtract(const Duration(days: 4))),
        duration: const Value(120),
        content: const Value('电磁感应专题复习，讲解了法拉第电磁感应定律'),
        homework: const Value('完成电磁感应专题试卷'),
        rating: const Value(4),
        createdAt: Value(now),
      ),
      // 上周记录
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[0].id),
        subject: const Value('数学'),
        date: Value(now.subtract(const Duration(days: 8))),
        duration: const Value(120),
        content: const Value('函数的单调性和极值，图像分析'),
        homework: const Value('复习笔记，完成作业'),
        rating: const Value(5),
        createdAt: Value(now),
      ),
      CourseRecordsCompanion(
        id: Value(_uuid.v4()),
        studentId: Value(students[1].id),
        subject: const Value('英语'),
        date: Value(now.subtract(const Duration(days: 9))),
        duration: const Value(120),
        content: const Value('写作技巧训练，如何写好议论文'),
        homework: const Value('写一篇关于环保的短文'),
        rating: const Value(4),
        createdAt: Value(now),
      ),
    ];

    for (final data in records) {
      await db.into(db.courseRecords).insert(data);
    }
  }
}
