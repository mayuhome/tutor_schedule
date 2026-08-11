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
import '../../../core/services/calendar_service.dart';
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
  bool _isSyncing = false;
  String? _calendarEventId;
  String? _currentScheduleId;

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
      _currentScheduleId = widget.scheduleId;
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
        if (_selectedStudentId != null) _updateAvailableSubjects();
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
            hour: schedule.startTime.hour, minute: schedule.startTime.minute);
        _endTime = TimeOfDay(
            hour: schedule.endTime.hour, minute: schedule.endTime.minute);
        _repeatRule = schedule.repeatRule;
        _repeatEndDate = schedule.repeatEndDate;
        _locationController.text = schedule.location ?? '';
        _reminderMinutes = schedule.reminderMinutes;
        _calendarEventId = schedule.calendarEventId;
        _updateAvailableSubjects();
      });
    }
  }

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
    final recordRepo = ref.read(courseRecordRepositoryProvider);
    final used = await recordRepo.getAllSubjects();
    final all = <String>{...preset, ...used}.toList();
    if (mounted) {
      setState(() {
        _availableSubjects = all;
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
      setState(() => isStart ? _startTime = time : _endTime = time);
    }
  }

  Future<void> _selectRepeatEndDate() async {
    final date = await showDatePicker(
      initialDate: _repeatEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      context: context,
    );
    if (date != null && mounted) setState(() => _repeatEndDate = date);
  }

  // ========== 日历同步 ==========

  Future<void> _syncToCalendar() async {
    if (_currentScheduleId == null) return;

    setState(() => _isSyncing = true);
    try {
      final calendarService = ref.read(calendarServiceProvider);

      // 检查权限
      bool hasPermission = await calendarService.hasPermissions();
      if (!hasPermission) {
        hasPermission = await calendarService.requestPermissions();
      }
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要日历权限才能同步')),
          );
        }
        return;
      }

      // 获取默认日历
      final calendar = await calendarService.getDefaultCalendar();
      if (calendar == null || calendar.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到可用的日历')),
          );
        }
        return;
      }

      // 构建课程开始/结束时间
      final startTime = _selectedDayOfWeek != null
          ? CalendarService.getNextOccurrence(
              _selectedDayOfWeek!, _startTime.hour, _startTime.minute)
          : DateTime.now();
      final endTime = startTime.add(
          Duration(hours: _endTime.hour - _startTime.hour,
              minutes: _endTime.minute - _startTime.minute));

      // 查找学生名
      final studentName = _students
          .where((s) => s.id == _selectedStudentId)
          .map((s) => s.name)
          .firstOrNull ?? '';

      final title = '$_selectedSubject - $studentName';
      final description = '家教课程\n学生: $studentName\n科目: $_selectedSubject';

      String? eventId;
      if (_calendarEventId != null && _calendarEventId!.isNotEmpty) {
        // 更新已有事件
        eventId = await calendarService.updateEvent(
          calendarId: calendar.id!,
          eventId: _calendarEventId!,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim() : null,
          reminderMinutes: _reminderMinutes,
          repeatRule: _repeatRule,
          repeatEndDate: _repeatEndDate,
        );
      } else {
        // 创建新事件
        eventId = await calendarService.createEvent(
          calendarId: calendar.id!,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim() : null,
          reminderMinutes: _reminderMinutes,
          repeatRule: _repeatRule,
          repeatEndDate: _repeatEndDate,
        );
      }

      if (eventId != null) {
        // 保存日历事件ID到数据库
        final repo = ref.read(scheduleRepositoryProvider);
        final schedule = await repo.getScheduleById(_currentScheduleId!);
        if (schedule != null) {
          await repo.updateSchedule(
              schedule.copyWith(calendarEventId: eventId));
          setState(() => _calendarEventId = eventId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_calendarEventId == eventId
                  ? '已同步到日历' : '已更新日历事件'),
              action: SnackBarAction(label: '确定', onPressed: () {}),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('同步失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步出错: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _removeCalendarSync() async {
    if (_calendarEventId == null || _currentScheduleId == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('取消同步'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('是否从系统日历中删除该课程事件？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final calendarService = ref.read(calendarServiceProvider);
      final calendar = await calendarService.getDefaultCalendar();
      if (calendar?.id != null) {
        await calendarService.deleteEvent(calendar!.id!, _calendarEventId!);
      }
      final repo = ref.read(scheduleRepositoryProvider);
      final schedule = await repo.getScheduleById(_currentScheduleId!);
      if (schedule != null) {
        await repo.updateSchedule(schedule.copyWith(calendarEventId: null));
      }
      setState(() => _calendarEventId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已从日历中移除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  // ========== 保存课程 ==========

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择学生')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startDateTime = DateTime(
          now.year, now.month, now.day, _startTime.hour, _startTime.minute);
      final endDateTime = DateTime(
          now.year, now.month, now.day, _endTime.hour, _endTime.minute);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('结束时间必须晚于开始时间')));
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedDayOfWeek != null) {
        final repo = ref.read(scheduleRepositoryProvider);
        final conflicts = await repo.getConflictingSchedules(
          _selectedDayOfWeek!, startDateTime, endDateTime,
          excludeId: widget.scheduleId,
        );
        if (conflicts.isNotEmpty && mounted) {
          final proceed = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('时间冲突'),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('该时间段已有 ${conflicts.length} 节课程，是否继续？'),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
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
            ? _locationController.text.trim() : null,
        isActive: true,
        reminderMinutes: _reminderMinutes,
        calendarEventId: _calendarEventId,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(scheduleRepositoryProvider);
      if (_isEditing) {
        await repo.updateSchedule(schedule);
      } else {
        final id = await repo.addSchedule(schedule);
        _currentScheduleId = id;
      }

      // 保存后提示同步到日历
      if (mounted) {
        _showSyncPrompt();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSyncPrompt() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('课程已保存'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('是否同步到系统日历？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('暂不'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _syncToCalendar();
              if (mounted) context.pop();
            },
            child: const Text('同步'),
          ),
        ],
      ),
    );
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    final isSynced = _calendarEventId != null && _calendarEventId!.isNotEmpty;

    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑课程' : '新建课程'),
        actions: [
          if (_isEditing && isSynced)
            IconButton(
              icon: const Icon(CupertinoIcons.delete_simple,
                  color: IosColors.systemRed, size: 22),
              onPressed: _removeCalendarSync,
              tooltip: '从日历移除',
            ),
          if (_isEditing)
            IconButton(
              icon: _isSyncing
                  ? const CupertinoActivityIndicator(radius: 10)
                  : Icon(
                      isSynced
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.calendar_badge_plus,
                      color: isSynced ? IosColors.systemGreen : IosColors.systemBlue,
                      size: 24,
                    ),
              onPressed: _isSyncing ? null : _syncToCalendar,
              tooltip: isSynced ? '更新日历' : '同步到日历',
            ),
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(12),
                child: CupertinoActivityIndicator())
          else
            TextButton(
              onPressed: _saveSchedule,
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
            // 同步状态提示
            if (_isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSynced
                      ? IosColors.systemGreen.withValues(alpha: 0.1)
                      : IosColors.systemOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSynced
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.exclamationmark_circle_fill,
                      size: 18,
                      color: isSynced ? IosColors.systemGreen : IosColors.systemOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSynced ? '已同步到系统日历' : '未同步到系统日历',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSynced ? IosColors.systemGreen : IosColors.systemOrange,
                        ),
                      ),
                    ),
                    if (!isSynced)
                      GestureDetector(
                        onTap: _isSyncing ? null : _syncToCalendar,
                        child: const Text('立即同步',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: IosColors.systemBlue)),
                      ),
                  ],
                ),
              ),

            // 基本信息
            _SectionHeader(title: '课程信息'),
            _GroupedContainer(children: [
              _PickerField(
                label: '学生',
                value: _students
                    .where((s) => s.id == _selectedStudentId)
                    .map((s) => s.name)
                    .firstOrNull,
                icon: CupertinoIcons.person,
                onTap: () => _showStudentPicker(context),
              ),
              _AutocompleteField(
                controller: _subjectController,
                label: '科目',
                options: _availableSubjects,
                onSelected: (v) => _selectedSubject = v,
              ),
            ]),

            const SizedBox(height: 20),
            _SectionHeader(title: '时间安排'),
            _GroupedContainer(children: [
              // 重复规则
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('重复规则',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: IosColors.secondaryLabel(context))),
                    const SizedBox(height: 10),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: _repeatRule,
                      children: const {
                        'none': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('单次', style: TextStyle(fontSize: 13))),
                        'weekly': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('每周', style: TextStyle(fontSize: 13))),
                        'biweekly': Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('双周', style: TextStyle(fontSize: 13))),
                      },
                      onValueChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _repeatRule = v;
                            if (v != 'none') {
                              _selectedDayOfWeek ??= DateTime.now().weekday;
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (_repeatRule != 'none') ...[
                Divider(height: 0.5, indent: 14,
                    color: IosColors.separator(context)),
                _PickerField(
                  label: '上课星期',
                  value: _selectedDayOfWeek != null
                      ? ['周一','周二','周三','周四','周五','周六','周日'][_selectedDayOfWeek! - 1]
                      : null,
                  icon: CupertinoIcons.calendar,
                  onTap: () => _showDayPicker(context),
                ),
              ],
              Divider(height: 0.5, indent: 14,
                  color: IosColors.separator(context)),
              // 时间选择
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: _TimeButton(
                      label: '开始',
                      time: _startTime,
                      onTap: () => _selectTime(true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(CupertinoIcons.arrow_right,
                        size: 18, color: IosColors.tertiaryLabel(context)),
                  ),
                  Expanded(
                    child: _TimeButton(
                      label: '结束',
                      time: _endTime,
                      onTap: () => _selectTime(false),
                    ),
                  ),
                ]),
              ),
              Divider(height: 0.5, indent: 14,
                  color: IosColors.separator(context)),
              // 地点
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(CupertinoIcons.location, size: 20,
                      color: IosColors.systemBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _locationController,
                      placeholder: '上课地点（选填）',
                      style: const TextStyle(fontSize: 15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 8),
                      decoration: null,
                    ),
                  ),
                ]),
              ),
              Divider(height: 0.5, indent: 46,
                  color: IosColors.separator(context)),
              // 提醒时间
              _PickerField(
                label: '提前提醒',
                value: _reminderMinutes == 0
                    ? '不提醒'
                    : _reminderMinutes < 60
                        ? '$_reminderMinutes 分钟前'
                        : '${_reminderMinutes ~/ 60} 小时前',
                icon: CupertinoIcons.bell,
                onTap: () => _showReminderPicker(context),
              ),
              if (_repeatRule != 'none') ...[
                Divider(height: 0.5, indent: 14,
                    color: IosColors.separator(context)),
                _PickerField(
                  label: '重复结束日期',
                  value: _repeatEndDate != null
                      ? DateFormat('yyyy年M月d日').format(_repeatEndDate!)
                      : '不设置',
                  icon: CupertinoIcons.calendar_badge_minus,
                  onTap: _selectRepeatEndDate,
                  trailing: _repeatEndDate != null
                      ? GestureDetector(
                          onTap: () => setState(() => _repeatEndDate = null),
                          child: const Icon(CupertinoIcons.clear_circled,
                              size: 22, color: IosColors.systemGray),
                        )
                      : null,
                ),
              ],
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ========== Pickers ==========

  void _showStudentPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx)),
          ]),
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
                });
                _updateAvailableSubjects();
              },
              children: _students
                  .map((s) => Center(
                      child: Text(s.name, style: const TextStyle(fontSize: 17))))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showDayPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx)),
          ]),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: (_selectedDayOfWeek ?? 1) - 1,
              ),
              onSelectedItemChanged: (i) {
                setState(() => _selectedDayOfWeek = i + 1);
              },
              children: const [
                Center(child: Text('周一', style: TextStyle(fontSize: 17))),
                Center(child: Text('周二', style: TextStyle(fontSize: 17))),
                Center(child: Text('周三', style: TextStyle(fontSize: 17))),
                Center(child: Text('周四', style: TextStyle(fontSize: 17))),
                Center(child: Text('周五', style: TextStyle(fontSize: 17))),
                Center(child: Text('周六', style: TextStyle(fontSize: 17))),
                Center(child: Text('周日', style: TextStyle(fontSize: 17))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showReminderPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx)),
          ]),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              onSelectedItemChanged: (i) {
                final values = [0, 15, 30, 60, 120];
                setState(() => _reminderMinutes = values[i]);
              },
              children: const [
                Center(child: Text('不提醒', style: TextStyle(fontSize: 17))),
                Center(child: Text('15分钟前', style: TextStyle(fontSize: 17))),
                Center(child: Text('30分钟前', style: TextStyle(fontSize: 17))),
                Center(child: Text('1小时前', style: TextStyle(fontSize: 17))),
                Center(child: Text('2小时前', style: TextStyle(fontSize: 17))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ========== iOS 风格组件 ==========

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

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailing,
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
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
              const SizedBox(width: 4),
              Icon(CupertinoIcons.right_chevron,
                  size: 16, color: IosColors.tertiaryLabel(context)),
            ],
          ]),
        ),
      ),
      Divider(height: 0.5, indent: 46, color: IosColors.separator(context)),
    ]);
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: IosColors.tertiaryBackground(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: IosColors.secondaryLabel(context))),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _AutocompleteField({
    required this.controller,
    required this.label,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(CupertinoIcons.book, size: 20, color: IosColors.systemBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 16),
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return options;
                return options.where((s) =>
                    s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: onSelected,
              fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                if (controller.text.isNotEmpty && ctrl.text != controller.text) {
                  ctrl.text = controller.text;
                }
                return CupertinoTextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  placeholder: '选择或输入科目',
                  style: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  decoration: null,
                  onChanged: (v) {
                    controller.text = v;
                    onSelected(v);
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (ctx, i) {
                          final opt = options.elementAt(i);
                          return ListTile(
                            dense: true,
                            title: Text(opt),
                            onTap: () => onSelected(opt),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
