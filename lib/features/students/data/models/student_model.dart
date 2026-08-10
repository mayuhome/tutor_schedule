import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class StudentModel {
  final String id;
  final String name;
  final String grade;
  final String? school;
  final String? phone;
  final String? parentPhone;
  final List<String> subjects;
  final List<String> tags;
  final String? notes;
  final String? avatarColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    this.school,
    this.phone,
    this.parentPhone,
    this.subjects = const [],
    this.tags = const [],
    this.notes,
    this.avatarColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromDb(Student student) {
    return StudentModel(
      id: student.id,
      name: student.name,
      grade: student.grade,
      school: student.school,
      phone: student.phone,
      parentPhone: student.parentPhone,
      subjects: List<String>.from(jsonDecode(student.subjects)),
      tags: List<String>.from(jsonDecode(student.tags)),
      notes: student.notes,
      avatarColor: student.avatarColor,
      createdAt: student.createdAt,
      updatedAt: student.updatedAt,
    );
  }

  StudentsCompanion toCompanion() {
    return StudentsCompanion.insert(
      id: id,
      name: name,
      grade: grade,
      school: Value(school),
      phone: Value(phone),
      parentPhone: Value(parentPhone),
      subjects: Value(jsonEncode(subjects)),
      tags: Value(jsonEncode(tags)),
      notes: Value(notes),
      avatarColor: Value(avatarColor),
    );
  }

  StudentModel copyWith({
    String? name,
    String? grade,
    String? school,
    String? phone,
    String? parentPhone,
    List<String>? subjects,
    List<String>? tags,
    String? notes,
    String? avatarColor,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      school: school ?? this.school,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      subjects: subjects ?? this.subjects,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      avatarColor: avatarColor ?? this.avatarColor,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
