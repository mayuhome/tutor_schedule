import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../course_fees/providers/course_fee_providers.dart';
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
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStudentId;
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now();
  int _duration = 60; // 默认1小时
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
    // TODO: Implement loading existing record for editing
  }

  Future<void> _updateAvailableSubjects() async {
    if (_students.isEmpty) return;
    final student = _students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => _students.first,
    );

    final presetSubjects = student.subjects
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    final repo = ref.read(courseRecordRepositoryProvider);
    final usedSubjects = await repo.getAllSubjects();

    final allSubjects = <String>{...presetSubjects, ...usedSubjects}.toList();

    if (mounted) {
      setState(() {
        _availableSubjects = allSubjects;
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
      _selectedStudentId!,
      _selectedSubject,
    );
    if (mounted) {
      setState(() {
        if (feeEntry != null) {
          _fee = feeEntry.calculateFee(_duration);
        } else {
          // 使用全局默认费率
          final hourlyRate = ref.read(hourlyRateProvider);
          _fee = hourlyRate * _duration / 60.0;
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
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        fee: _fee,
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
                  _selectedSubject = '';
                  _subjectController.clear();
                  _fee = null;
                });
                _updateAvailableSubjects();
              },
            ),
            const SizedBox(height: 16),

            // 科目选择
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _availableSubjects;
                }
                return _availableSubjects.where((subject) =>
                    subject
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _selectedSubject = selection;
                _subjectController.text = selection;
                _calculateFee();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                if (_subjectController.text != controller.text &&
                    _subjectController.text.isNotEmpty) {
                  controller.text = _subjectController.text;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: '科目 *',
                    prefixIcon: const Icon(Icons.book),
                    hintText: '选择或输入科目名称',
                    suffixIcon: _availableSubjects.isNotEmpty
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (value) {
                              _selectedSubject = value;
                              controller.text = value;
                              _calculateFee();
                            },
                            itemBuilder: (context) =>
                                _availableSubjects.map((subject) {
                              return PopupMenuItem(
                                value: subject,
                                child: Text(subject),
                              );
                            }).toList(),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入科目名称';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _selectedSubject = value.trim();
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 日期选择
            ListTile(
              title: const Text('上课日期'),
              subtitle:
                  Text(DateFormat('yyyy年MM月dd日').format(_selectedDate)),
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
                _calculateFee();
              },
            ),
            // 费用显示
            if (_fee != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '本次费用: ¥${_fee!.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
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
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                hintText: '可选，补充说明或其他信息',
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
