import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/student_providers.dart';
import '../data/models/student_model.dart';
import '../../course_fees/providers/course_fee_providers.dart';
import '../../course_fees/data/models/course_fee_model.dart';

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
  final _feeRateController = TextEditingController();

  List<String> _subjects = [];
  final Map<String, double> _subjectFees = {};
  List<CourseFeeModel> _existingFees = [];
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _feeRateController.text = '200';
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
      _loadFees();
    }
  }

  Future<void> _loadFees() async {
    if (widget.studentId == null) return;
    final feeRepo = ref.read(courseFeeRepositoryProvider);
    final fees = await feeRepo.getFeesByStudent(widget.studentId!);
    if (mounted) {
      setState(() {
        _existingFees = fees;
        for (final fee in fees) {
          _subjectFees[fee.subject] = fee.feePerHour;
        }
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
    _feeRateController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(studentRepositoryProvider);
      final studentId = widget.studentId ?? const Uuid().v4();
      final student = StudentModel(
        id: studentId,
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

      // 保存科目费用
      final feeRepo = ref.read(courseFeeRepositoryProvider);
      for (final subject in _subjects) {
        final feeRate = _subjectFees[subject];
        if (feeRate != null && feeRate > 0) {
          final existingFee = _existingFees
              .where((f) => f.subject == subject)
              .toList();
          if (existingFee.isNotEmpty) {
            await feeRepo.updateFee(CourseFeeModel(
              id: existingFee.first.id,
              studentId: studentId,
              subject: subject,
              feePerHour: feeRate,
              createdAt: existingFee.first.createdAt,
            ));
          } else {
            await feeRepo.addFee(CourseFeeModel(
              id: '',
              studentId: studentId,
              subject: subject,
              feePerHour: feeRate,
              createdAt: DateTime.now(),
            ));
          }
        }
      }

      // 删除已移除科目的费用
      for (final fee in _existingFees) {
        if (!_subjects.contains(fee.subject)) {
          await feeRepo.deleteFee(fee.id);
        }
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
      final feeRate = double.tryParse(_feeRateController.text) ?? 200;
      setState(() {
        _subjects.add(subject);
        _subjectFees[subject] = feeRate;
        _subjectController.clear();
      });
    }
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
      _subjectFees.remove(subject);
    });
  }

  void _editSubjectFee(String subject) {
    final currentFee = _subjectFees[subject] ?? 200;
    final controller =
        TextEditingController(text: currentFee.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置「$subject」课时费'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每小时费用',
            prefixText: '¥',
            suffixText: '元/小时',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0) {
                setState(() => _subjectFees[subject] = rate);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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

            // 科目及课时费
            Text(
              '科目及课时费',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_subjects.isNotEmpty) ...[
              ..._subjects.map((subject) {
                final fee = _subjectFees[subject];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Icon(Icons.book,
                          color: theme.colorScheme.primary),
                    ),
                    title: Text(subject),
                    subtitle: Text(
                      fee != null ? '¥${fee.toStringAsFixed(0)}/小时' : '未设置',
                      style: TextStyle(
                        color: fee != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editSubjectFee(subject),
                          tooltip: '编辑费用',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeSubject(subject),
                          tooltip: '删除科目',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: '科目名称',
                      hintText: '如：数学',
                    ),
                    onFieldSubmitted: (_) => _addSubject(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _feeRateController,
                    decoration: const InputDecoration(
                      labelText: '课时费',
                      prefixText: '¥',
                      suffixText: '/h',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton.filled(
                    onPressed: _addSubject,
                    icon: const Icon(Icons.add),
                  ),
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
