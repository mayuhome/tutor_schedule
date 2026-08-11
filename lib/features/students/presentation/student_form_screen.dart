import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/color_schemes.dart';
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
            ? _schoolController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim() : null,
        parentPhone: _parentPhoneController.text.trim().isNotEmpty
            ? _parentPhoneController.text.trim() : null,
        subjects: _subjects,
        tags: _tags,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (_isEditing) {
        await repo.updateStudent(student);
      } else {
        await repo.addStudent(student);
      }
      final feeRepo = ref.read(courseFeeRepositoryProvider);
      for (final subject in _subjects) {
        final feeRate = _subjectFees[subject];
        if (feeRate != null && feeRate > 0) {
          final existingFee =
              _existingFees.where((f) => f.subject == subject).toList();
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
              id: '', studentId: studentId, subject: subject,
              feePerHour: feeRate, createdAt: DateTime.now(),
            ));
          }
        }
      }
      for (final fee in _existingFees) {
        if (!_subjects.contains(fee.subject)) {
          await feeRepo.deleteFee(fee.id);
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('设置「$subject」课时费'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('¥', style: TextStyle(fontSize: 16)),
            ),
            suffix: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('/小时', style: TextStyle(fontSize: 14, color: IosColors.systemGray)),
            ),
            placeholder: '费用',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑学生' : '添加学生'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CupertinoActivityIndicator(),
            )
          else
            TextButton(
              onPressed: _saveStudent,
              child: const Text('保存',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: IosColors.systemBlue)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            _SectionHeader(title: '基本信息'),
            _GroupedContainer(
              children: [
                _IOSField(
                  controller: _nameController,
                  label: '姓名',
                  placeholder: '学生姓名',
                  icon: CupertinoIcons.person,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入姓名' : null,
                ),
                _IOSField(
                  controller: _gradeController,
                  label: '年级',
                  placeholder: '如：高一、初三',
                  icon: CupertinoIcons.book,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入年级' : null,
                ),
                _IOSField(
                  controller: _schoolController,
                  label: '学校',
                  placeholder: '选填',
                  icon: CupertinoIcons.building_2_fill,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: '联系方式'),
            _GroupedContainer(
              children: [
                _IOSField(
                  controller: _phoneController,
                  label: '学生电话',
                  placeholder: '选填',
                  icon: CupertinoIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _IOSField(
                  controller: _parentPhoneController,
                  label: '家长电话',
                  placeholder: '选填',
                  icon: CupertinoIcons.person_2,
                  keyboardType: TextInputType.phone,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: '科目及课时费'),
            if (_subjects.isNotEmpty)
              _GroupedContainer(
                children: [
                  for (int i = 0; i < _subjects.length; i++)
                    _SubjectFeeRow(
                      subject: _subjects[i],
                      fee: _subjectFees[_subjects[i]],
                      onEdit: () => _editSubjectFee(_subjects[i]),
                      onDelete: () => _removeSubject(_subjects[i]),
                      isLast: i == _subjects.length - 1,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            _GroupedContainer(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CupertinoTextField(
                          controller: _subjectController,
                          placeholder: '科目名称',
                          style: const TextStyle(fontSize: 15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: IosColors.tertiaryBackground(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSubmitted: (_) => _addSubject(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CupertinoTextField(
                          controller: _feeRateController,
                          placeholder: '费用',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 15),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text('¥',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: IosColors.systemGray)),
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text('/h',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: IosColors.systemGray)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: IosColors.tertiaryBackground(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addSubject,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: IosColors.systemBlue,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(CupertinoIcons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: '备注'),
            _GroupedContainer(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: CupertinoTextField(
                    controller: _notesController,
                    placeholder: '学生特点、学习情况等',
                    maxLines: 4,
                    style: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IosColors.tertiaryBackground(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// iOS 分组头部
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: IosColors.secondaryLabel(context))),
    );
  }
}

// iOS 分组容器
class _GroupedContainer extends StatelessWidget {
  final List<Widget> children;
  const _GroupedContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IosColors.secondaryBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// iOS 风格表单字段
class _IOSField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isLast;

  const _IOSField({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(label,
                    style: const TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0, vertical: 8),
                  decoration: null,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 0.5,
              indent: 14,
              color: IosColors.separator(context)),
      ],
    );
  }
}

// 科目费用行
class _SubjectFeeRow extends StatelessWidget {
  final String subject;
  final double? fee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLast;

  const _SubjectFeeRow({
    required this.subject,
    required this.fee,
    required this.onEdit,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(CupertinoIcons.book,
                  size: 18, color: AppColors.subjectColor(subject)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(subject,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  fee != null
                      ? '¥${fee!.toStringAsFixed(0)}/小时'
                      : '未设置',
                  style: TextStyle(
                    fontSize: 14,
                    color: fee != null
                        ? IosColors.systemBlue
                        : IosColors.tertiaryLabel(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(CupertinoIcons.minus_circle,
                    size: 22, color: IosColors.systemRed),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 0.5,
              indent: 42,
              color: IosColors.separator(context)),
      ],
    );
  }
}
