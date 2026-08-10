import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/student_providers.dart';
import '../data/models/student_model.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentFormScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _subjectController = TextEditingController();

  List<String> _subjects = [];
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _isEditing = true;
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    final repo = ref.read(studentRepositoryProvider);
    final student = await repo.getStudentById(widget.studentId!);
    if (student != null && mounted) {
      setState(() {
        _nameController.text = student.name;
        _gradeController.text = student.grade;
        _schoolController.text = student.school ?? '';
        _phoneController.text = student.phone ?? '';
        _parentPhoneController.text = student.parentPhone ?? '';
        _notesController.text = student.notes ?? '';
        _subjects = List.from(student.subjects);
        _tags = List.from(student.tags);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(studentRepositoryProvider);
      final student = StudentModel(
        id: widget.studentId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        grade: _gradeController.text.trim(),
        school: _schoolController.text.trim().isNotEmpty
            ? _schoolController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        parentPhone: _parentPhoneController.text.trim().isNotEmpty
            ? _parentPhoneController.text.trim()
            : null,
        subjects: _subjects,
        tags: _tags,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await repo.updateStudent(student);
      } else {
        await repo.addStudent(student);
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

  void _addSubject() {
    final subject = _subjectController.text.trim();
    if (subject.isNotEmpty && !_subjects.contains(subject)) {
      setState(() {
        _subjects.add(subject);
        _subjectController.clear();
      });
    }
  }

  void _removeSubject(String subject) {
    setState(() => _subjects.remove(subject));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑学生' : '添加学生'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStudent,
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
            // 基本信息
            Text(
              '基本信息',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名 *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入学生姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: '年级 *',
                prefixIcon: Icon(Icons.school),
                hintText: '如：高一、初三',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入年级';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: '学校',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 24),

            // 联系方式
            Text(
              '联系方式',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '学生电话',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _parentPhoneController,
              decoration: const InputDecoration(
                labelText: '家长电话',
                prefixIcon: Icon(Icons.contact_phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // 科目
            Text(
              '科目',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects.map((subject) {
                return Chip(
                  label: Text(subject),
                  onDeleted: () => _removeSubject(subject),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: '添加科目',
                      hintText: '如：数学、英语',
                    ),
                    onFieldSubmitted: (_) => _addSubject(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSubject,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 备注
            Text(
              '备注',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注信息',
                prefixIcon: Icon(Icons.note),
                hintText: '学生特点、学习情况等',
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
