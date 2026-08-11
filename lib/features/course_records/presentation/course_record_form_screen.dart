import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/color_schemes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../course_fees/providers/course_fee_providers.dart';
import '../providers/course_record_providers.dart';
import '../data/models/course_record_model.dart';

class CourseRecordFormScreen extends ConsumerStatefulWidget {
  final String? recordId;
  final String? initialStudentId;
  const CourseRecordFormScreen({super.key, this.recordId, this.initialStudentId});

  @override
  ConsumerState<CourseRecordFormScreen> createState() =>
      _CourseRecordFormScreenState();
}

class _CourseRecordFormScreenState
    extends ConsumerState<CourseRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStudentId;
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now();
  int _duration = 60;
  int _rating = 3;
  double? _fee;
  bool _isLoading = false;
  bool _isEditing = false;
  List<Student> _students = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _loadStudents();
    if (widget.recordId != null) { _isEditing = true; _loadRecord(); }
  }

  Future<void> _loadStudents() async {
    final db = ref.read(databaseProvider);
    final students = await StudentDao(db).getAllStudents();
    if (mounted) {
      setState(() {
        _students = students;
        if (_selectedStudentId != null) _updateAvailableSubjects();
      });
    }
  }

  Future<void> _loadRecord() async {}

  Future<void> _updateAvailableSubjects() async {
    if (_students.isEmpty) return;
    final student = _students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => _students.first,
    );
    final preset = student.subjects
        .replaceAll(RegExp(r'[\[\]"]'), '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    final repo = ref.read(courseRecordRepositoryProvider);
    final used = await repo.getAllSubjects();
    final all = <String>{...preset, ...used}.toList();
    if (mounted) {
      setState(() {
        _availableSubjects = all;
        if (_selectedSubject.isEmpty && _availableSubjects.isNotEmpty) {
          _selectedSubject = _availableSubjects.first;
          _subjectController.text = _selectedSubject;
          _calculateFee();
        }
      });
    }
  }

  Future<void> _calculateFee() async {
    if (_selectedStudentId == null || _selectedSubject.isEmpty) return;
    final feeRepo = ref.read(courseFeeRepositoryProvider);
    final feeEntry = await feeRepo.getFeeByStudentAndSubject(
        _selectedStudentId!, _selectedSubject);
    if (mounted) {
      setState(() {
        if (feeEntry != null) {
          _fee = feeEntry.calculateFee(_duration);
        } else {
          _fee = ref.read(hourlyRateProvider) * _duration / 60.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    _homeworkController.dispose();
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context, _selectedDate),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) => _selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    );
    if (date != null && mounted) setState(() {});
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择学生')));
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
            ? _homeworkController.text.trim() : null,
        rating: _rating,
        summary: _summaryController.text.trim().isNotEmpty
            ? _summaryController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim() : null,
        fee: _fee,
        createdAt: DateTime.now(),
      );
      final repo = ref.read(courseRecordRepositoryProvider);
      _isEditing ? await repo.updateRecord(record) : await repo.addRecord(record);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '新建课程记录'),
        actions: [
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(12),
                child: CupertinoActivityIndicator())
          else
            TextButton(
              onPressed: _saveRecord,
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
            _SectionHeader(title: '基本信息'),
            _GroupedContainer(children: [
              // 学生
              _PickerField(
                label: '学生',
                value: _students
                    .where((s) => s.id == _selectedStudentId)
                    .map((s) => s.name)
                    .firstOrNull,
                icon: CupertinoIcons.person,
                onTap: () => _showStudentPicker(context),
              ),
              // 科目
              _PickerField(
                label: '科目',
                value: _selectedSubject.isNotEmpty ? _selectedSubject : null,
                icon: CupertinoIcons.book,
                onTap: () => _showSubjectPicker(context),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 20),
            _SectionHeader(title: '课程详情'),
            _GroupedContainer(children: [
              _PickerField(
                label: '日期',
                value: DateFormat('yyyy年M月d日').format(_selectedDate),
                icon: CupertinoIcons.calendar,
                onTap: _selectDate,
              ),
              // 时长
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('时长',
                            style: TextStyle(fontSize: 15)),
                        Text('$_duration 分钟',
                            style: const TextStyle(
                                fontSize: 15,
                                color: IosColors.systemBlue)),
                      ],
                    ),
                    CupertinoSlider(
                      value: _duration.toDouble(),
                      min: 30,
                      max: 240,
                      divisions: 21,
                      onChanged: (v) {
                        setState(() => _duration = v.round());
                        _calculateFee();
                      },
                    ),
                  ],
                ),
              ),
              // 费用
              if (_fee != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.money_dollar_circle,
                          size: 22, color: IosColors.systemBlue),
                      const SizedBox(width: 8),
                      Text('本次费用: ¥${_fee!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: IosColors.systemBlue)),
                    ],
                  ),
                ),
              // 评分
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('学生表现评分',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: IosColors.secondaryLabel(context))),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            i < _rating
                                ? CupertinoIcons.star_fill
                                : CupertinoIcons.star,
                            size: 32,
                            color: i < _rating
                                ? IosColors.systemYellow
                                : IosColors.tertiaryLabel(context),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 20),
            _SectionHeader(title: '教学内容'),
            _GroupedContainer(children: [
              _TextAreaField(
                controller: _contentController,
                placeholder: '本节课主要讲解的内容',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入教学内容' : null,
              ),
            ]),

            const SizedBox(height: 20),
            _SectionHeader(title: '作业与总结'),
            _GroupedContainer(children: [
              _TextAreaField(
                controller: _homeworkController,
                placeholder: '布置的课后作业',
              ),
              Divider(height: 0.5, indent: 14,
                  color: IosColors.separator(context)),
              _TextAreaField(
                controller: _summaryController,
                placeholder: '对学生本节课表现的总结',
              ),
            ]),

            const SizedBox(height: 20),
            _SectionHeader(title: '备注'),
            _GroupedContainer(children: [
              _TextAreaField(
                controller: _notesController,
                placeholder: '可选，补充说明或其他信息',
                isLast: true,
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showStudentPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: _students
                    .indexWhere((s) => s.id == _selectedStudentId)
                    .clamp(0, _students.length - 1),
              ),
              onSelectedItemChanged: (i) {
                setState(() {
                  _selectedStudentId = _students[i].id;
                  _selectedSubject = '';
                  _subjectController.clear();
                  _fee = null;
                });
                _updateAvailableSubjects();
              },
              children: _students
                  .map((s) => Center(
                      child: Text(s.name,
                          style: const TextStyle(fontSize: 17))))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSubjectPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          Expanded(
            child: _availableSubjects.isEmpty
                ? const Center(child: Text('暂无科目'))
                : CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      setState(() {
                        _selectedSubject = _availableSubjects[i];
                        _subjectController.text = _selectedSubject;
                      });
                      _calculateFee();
                    },
                    children: _availableSubjects
                        .map((s) => Center(
                            child: Text(s,
                                style: const TextStyle(fontSize: 17))))
                        .toList(),
                  ),
          ),
        ]),
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

// iOS 选择器字段
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 20, color: IosColors.systemBlue),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(value ?? '请选择',
                style: TextStyle(
                    fontSize: 15,
                    color: value != null
                        ? IosColors.secondaryLabel(context)
                        : IosColors.tertiaryLabel(context))),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.right_chevron,
                size: 16, color: IosColors.tertiaryLabel(context)),
          ]),
        ),
      ),
      if (!isLast)
        Divider(height: 0.5, indent: 46,
            color: IosColors.separator(context)),
    ]);
  }
}

// iOS 多行输入
class _TextAreaField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? Function(String?)? validator;
  final bool isLast;

  const _TextAreaField({
    required this.controller,
    required this.placeholder,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 15),
        maxLines: 3,
        validator: validator,
      ),
    );
  }
}
