import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/student_dao.dart';
import '../providers/course_record_providers.dart';
import '../data/models/course_record_model.dart';

class CourseRecordFormScreen extends ConsumerStatefulWidget {
  final String? recordId;
  final String? initialStudentId;

  const CourseRecordFormScreen({
    super.key,
    this.recordId,
    this.initialStudentId,
  });

  @override
  ConsumerState<CourseRecordFormScreen> createState() =>
      _CourseRecordFormScreenState();
}

class _CourseRecordFormScreenState
    extends ConsumerState<CourseRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _summaryController = TextEditingController();

  String? _selectedStudentId;
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now();
  int _duration = 90;
  int _rating = 3;
  bool _isLoading = false;
  bool _isEditing = false;

  List<Student> _students = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _loadStudents();
    if (widget.recordId != null) {
      _isEditing = true;
      _loadRecord();
    }
  }

  Future<void> _loadStudents() async {
    final db = ref.read(databaseProvider);
    final dao = StudentDao(db);
    final students = await dao.getAllStudents();
    if (mounted) {
      setState(() {
        _students = students;
        if (_selectedStudentId != null) {
          _updateAvailableSubjects();
        }
      });
    }
  }

  Future<void> _loadRecord() async {
    final repo = ref.read(courseRecordRepositoryProvider);
    // TODO: Add getRecordById to repository
  }

  void _updateAvailableSubjects() {
    if (_students.isEmpty) return;
    final student = _students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => _students.first,
    );
    final subjectsStr = student.subjects;
    _availableSubjects = subjectsStr
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    if (_availableSubjects.isNotEmpty &&
        !_availableSubjects.contains(_selectedSubject)) {
      _selectedSubject = _availableSubjects.first;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _homeworkController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择学生')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final record = CourseRecordModel(
        id: widget.recordId ?? const Uuid().v4(),
        studentId: _selectedStudentId!,
        subject: _selectedSubject,
        date: _selectedDate,
        duration: _duration,
        content: _contentController.text.trim(),
        homework: _homeworkController.text.trim().isNotEmpty
            ? _homeworkController.text.trim()
            : null,
        rating: _rating,
        summary: _summaryController.text.trim().isNotEmpty
            ? _summaryController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(courseRecordRepositoryProvider);
      if (_isEditing) {
        await repo.updateRecord(record);
      } else {
        await repo.addRecord(record);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '新建课程记录'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecord,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 学生选择
            DropdownButtonFormField<String>(
              value: _selectedStudentId,
              decoration: const InputDecoration(
                labelText: '选择学生 *',
                prefixIcon: Icon(Icons.person),
              ),
              items: _students.map((student) {
                return DropdownMenuItem(
                  value: student.id,
                  child: Text(student.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                  _updateAvailableSubjects();
                });
              },
            ),
            const SizedBox(height: 16),

            // 科目选择
            if (_availableSubjects.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedSubject.isNotEmpty ? _selectedSubject : null,
                decoration: const InputDecoration(
                  labelText: '科目 *',
                  prefixIcon: Icon(Icons.book),
                ),
                items: _availableSubjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value ?? '');
                },
              )
            else
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '科目 *',
                  prefixIcon: Icon(Icons.book),
                ),
                onChanged: (value) => _selectedSubject = value,
              ),
            const SizedBox(height: 16),

            // 日期选择
            ListTile(
              title: const Text('上课日期'),
              subtitle: Text(DateFormat('yyyy年MM月dd日').format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 16),

            // 时长选择
            Text(
              '课程时长: $_duration 分钟',
              style: theme.textTheme.titleSmall,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 30,
              max: 240,
              divisions: 21,
              label: '$_duration 分钟',
              onChanged: (value) {
                setState(() => _duration = value.round());
              },
            ),
            const SizedBox(height: 16),

            // 评分
            Text(
              '学生表现评分',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: index < _rating
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // 教学内容
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '教学内容 *',
                prefixIcon: Icon(Icons.description),
                hintText: '本节课主要讲解的内容',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入教学内容';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 作业布置
            TextFormField(
              controller: _homeworkController,
              decoration: const InputDecoration(
                labelText: '作业布置',
                prefixIcon: Icon(Icons.assignment),
                hintText: '布置的课后作业',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // 学习总结
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: '学习总结',
                prefixIcon: Icon(Icons.summarize),
                hintText: '对学生本节课表现的总结',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
