import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/student_dao.dart';
import '../../../features/course_records/providers/course_record_providers.dart';
import '../providers/schedule_providers.dart';
import '../data/models/schedule_model.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String? scheduleId;
  final String? initialStudentId;

  const ScheduleFormScreen({
    super.key,
    this.scheduleId,
    this.initialStudentId,
  });

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedStudentId;
  String _selectedSubject = '';
  int? _selectedDayOfWeek;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  String _repeatRule = 'none';
  DateTime? _repeatEndDate;
  int _reminderMinutes = 30;
  bool _isLoading = false;
  bool _isEditing = false;

  List<Student> _students = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _selectedDayOfWeek = DateTime.now().weekday;
    _loadStudents();
    if (widget.scheduleId != null) {
      _isEditing = true;
      _loadSchedule();
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

  Future<void> _loadSchedule() async {
    final repo = ref.read(scheduleRepositoryProvider);
    final schedule = await repo.getScheduleById(widget.scheduleId!);
    if (schedule != null && mounted) {
      setState(() {
        _selectedStudentId = schedule.studentId;
        _selectedSubject = schedule.subject;
        _subjectController.text = schedule.subject;
        _selectedDayOfWeek = schedule.dayOfWeek;
        _startTime = TimeOfDay(
          hour: schedule.startTime.hour,
          minute: schedule.startTime.minute,
        );
        _endTime = TimeOfDay(
          hour: schedule.endTime.hour,
          minute: schedule.endTime.minute,
        );
        _repeatRule = schedule.repeatRule;
        _repeatEndDate = schedule.repeatEndDate;
        _locationController.text = schedule.location ?? '';
        _reminderMinutes = schedule.reminderMinutes;
        _updateAvailableSubjects();
      });
    }
  }

  /// 合并学生预设科目 + 数据库中已使用过的科目
  Future<void> _updateAvailableSubjects() async {
    if (_students.isEmpty) return;
    final student = _students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => _students.first,
    );

    // 学生预设科目
    final presetSubjects = student.subjects
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // 数据库中所有已使用过的科目
    final recordRepo = ref.read(courseRecordRepositoryProvider);
    final usedSubjects = await recordRepo.getAllSubjects();

    // 合并去重
    final allSubjects = <String>{...presetSubjects, ...usedSubjects}.toList();

    if (mounted) {
      setState(() {
        _availableSubjects = allSubjects;
        if (_selectedSubject.isEmpty && _availableSubjects.isNotEmpty) {
          _selectedSubject = _availableSubjects.first;
          _subjectController.text = _selectedSubject;
        }
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _selectRepeatEndDate() async {
    final date = await showDatePicker(
      initialDate: _repeatEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      context: context,
    );
    if (date != null && mounted) {
      setState(() => _repeatEndDate = date);
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择学生')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDateTime = DateTime(
        now.year, now.month, now.day,
        _startTime.hour, _startTime.minute,
      );
      final endDateTime = DateTime(
        now.year, now.month, now.day,
        _endTime.hour, _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('结束时间必须晚于开始时间')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Check for conflicts
      if (_selectedDayOfWeek != null) {
        final repo = ref.read(scheduleRepositoryProvider);
        final conflicts = await repo.getConflictingSchedules(
          _selectedDayOfWeek!,
          startDateTime,
          endDateTime,
          excludeId: widget.scheduleId,
        );
        if (conflicts.isNotEmpty && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('时间冲突'),
              content: Text('该时间段已有 ${conflicts.length} 节课程，是否继续？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('继续'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      final schedule = ScheduleModel(
        id: widget.scheduleId ?? const Uuid().v4(),
        studentId: _selectedStudentId!,
        subject: _selectedSubject,
        dayOfWeek: _selectedDayOfWeek,
        startTime: startDateTime,
        endTime: endDateTime,
        repeatRule: _repeatRule,
        repeatEndDate: _repeatEndDate,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        isActive: true,
        reminderMinutes: _reminderMinutes,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(scheduleRepositoryProvider);
      if (_isEditing) {
        await repo.updateSchedule(schedule);
      } else {
        await repo.addSchedule(schedule);
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
        title: Text(_isEditing ? '编辑课程' : '新建课程'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSchedule,
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
                });
                _updateAvailableSubjects();
              },
              validator: (value) {
                if (value == null) return '请选择学生';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 科目选择（支持选择已有科目 + 手动输入新科目）
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
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
            const SizedBox(height: 24),

            // 重复规则
            Text(
              '重复规则',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'none', label: Text('单次')),
                ButtonSegment(value: 'weekly', label: Text('每周')),
                ButtonSegment(value: 'biweekly', label: Text('双周')),
              ],
              selected: {_repeatRule},
              onSelectionChanged: (values) {
                setState(() {
                  _repeatRule = values.first;
                  if (_repeatRule != 'none') {
                    _selectedDayOfWeek = _selectedDayOfWeek ?? DateTime.now().weekday;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // 星期选择（重复课程时显示）
            if (_repeatRule != 'none') ...[
              DropdownButtonFormField<int>(
                value: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  labelText: '上课星期',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('周一')),
                  DropdownMenuItem(value: 2, child: Text('周二')),
                  DropdownMenuItem(value: 3, child: Text('周三')),
                  DropdownMenuItem(value: 4, child: Text('周四')),
                  DropdownMenuItem(value: 5, child: Text('周五')),
                  DropdownMenuItem(value: 6, child: Text('周六')),
                  DropdownMenuItem(value: 7, child: Text('周日')),
                ],
                onChanged: (value) {
                  setState(() => _selectedDayOfWeek = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // 时间选择
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('开始时间'),
                    subtitle: Text(_startTime.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('结束时间'),
                    subtitle: Text(_endTime.format(context)),
                    leading: const Icon(Icons.access_time_filled),
                    onTap: () => _selectTime(false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点',
                prefixIcon: Icon(Icons.location_on),
                hintText: '可选',
              ),
            ),
            const SizedBox(height: 16),

            // 提醒时间
            DropdownButtonFormField<int>(
              value: _reminderMinutes,
              decoration: const InputDecoration(
                labelText: '提前提醒',
                prefixIcon: Icon(Icons.notifications),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('不提醒')),
                DropdownMenuItem(value: 15, child: Text('15分钟前')),
                DropdownMenuItem(value: 30, child: Text('30分钟前')),
                DropdownMenuItem(value: 60, child: Text('1小时前')),
                DropdownMenuItem(value: 120, child: Text('2小时前')),
              ],
              onChanged: (value) {
                setState(() => _reminderMinutes = value ?? 30);
              },
            ),
            const SizedBox(height: 16),

            // 结束重复日期
            if (_repeatRule != 'none') ...[
              ListTile(
                title: const Text('重复结束日期'),
                subtitle: Text(
                  _repeatEndDate != null
                      ? DateFormat('yyyy年MM月dd日').format(_repeatEndDate!)
                      : '不设置',
                ),
                leading: const Icon(Icons.event_busy),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_repeatEndDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _repeatEndDate = null);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectRepeatEndDate,
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
