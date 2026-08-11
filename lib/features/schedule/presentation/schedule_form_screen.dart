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

// ========== 时间段数据模型 ==========

class TimeSlot {
  int dayOfWeek;
  TimeOfDay startTime;
  TimeOfDay endTime;

  TimeSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  String get dayName =>
      ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][dayOfWeek - 1];

  String get timeRange =>
      '${_fmt(startTime)} - ${_fmt(endTime)}';

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ========== 表单主页面 ==========

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String? scheduleId;
  final String? initialStudentId;

  const ScheduleFormScreen({super.key, this.scheduleId, this.initialStudentId});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedStudentId;
  String _selectedSubject = '';
  String _repeatRule = 'none';
  DateTime? _repeatEndDate;
  int _biweeklyOffset = 0; // 0=本周开始, 1=下周开始
  int _reminderMinutes = 30;
  bool _isLoading = false;
  bool _isEditing = false;

  // 时间段列表
  List<TimeSlot> _timeSlots = [];

  // 编辑模式：组ID 和已有 schedule 记录
  String? _groupId;
  List<ScheduleModel> _existingSchedules = [];

  List<Student> _students = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    // 默认一个时间段：当前星期几
    _timeSlots.add(TimeSlot(
      dayOfWeek: DateTime.now().weekday,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 30),
    ));
    _loadStudents();
    if (widget.scheduleId != null) {
      _isEditing = true;
      _loadSchedule();
    }
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

  Future<void> _loadSchedule() async {
    final repo = ref.read(scheduleRepositoryProvider);
    final schedule = await repo.getScheduleById(widget.scheduleId!);
    if (schedule == null || !mounted) return;

    // 如果是分组课程，加载整个组
    List<ScheduleModel> groupSchedules = [schedule];
    if (schedule.isInGroup) {
      _groupId = schedule.scheduleGroupId;
      groupSchedules = await repo.getSchedulesByGroup(_groupId!);
    }

    setState(() {
      _selectedStudentId = schedule.studentId;
      _selectedSubject = schedule.subject;
      _subjectController.text = schedule.subject;
      _repeatRule = schedule.repeatRule;
      _repeatEndDate = schedule.repeatEndDate;
      _biweeklyOffset = schedule.biweeklyOffset;
      _locationController.text = schedule.location ?? '';
      _reminderMinutes = schedule.reminderMinutes;
      _existingSchedules = groupSchedules;
      _timeSlots = groupSchedules.map((s) => TimeSlot(
        dayOfWeek: s.dayOfWeek ?? DateTime.now().weekday,
        startTime: TimeOfDay(
            hour: s.startTime.hour, minute: s.startTime.minute),
        endTime: TimeOfDay(
            hour: s.endTime.hour, minute: s.endTime.minute),
      )).toList();
      _updateAvailableSubjects();
    });
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
        .where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
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

  // ========== 时间段操作 ==========

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(TimeSlot(
        dayOfWeek: DateTime.now().weekday,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
      ));
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots.length <= 1) return; // 至少保留一个
    setState(() => _timeSlots.removeAt(index));
  }

  Future<void> _editTimeSlot(int index) async {
    final slot = _timeSlots[index];
    int tempDay = slot.dayOfWeek;
    TimeOfDay tempStart = slot.startTime;
    TimeOfDay tempEnd = slot.endTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 380,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoButton(
                child: const Text('完成'),
                onPressed: () {
                  setState(() {
                    _timeSlots[index] = TimeSlot(
                      dayOfWeek: tempDay,
                      startTime: tempStart,
                      endTime: tempEnd,
                    );
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          Expanded(
            child: Row(children: [
              // 星期选择
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController:
                      FixedExtentScrollController(initialItem: tempDay - 1),
                  onSelectedItemChanged: (i) => tempDay = i + 1,
                  children: const [
                    Center(child: Text('周一', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周二', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周三', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周四', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周五', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周六', style: TextStyle(fontSize: 16))),
                    Center(child: Text('周日', style: TextStyle(fontSize: 16))),
                  ],
                ),
              ),
              // 开始时间
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2024, 1, 1,
                      tempStart.hour, tempStart.minute),
                  use24hFormat: true,
                  onDateTimeChanged: (dt) =>
                      tempStart = TimeOfDay(hour: dt.hour, minute: dt.minute),
                ),
              ),
              // 结束时间
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                      2024, 1, 1, tempEnd.hour, tempEnd.minute),
                  use24hFormat: true,
                  onDateTimeChanged: (dt) =>
                      tempEnd = TimeOfDay(hour: dt.hour, minute: dt.minute),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ========== 日历同步 ==========

  Future<void> _syncToCalendar() async {
    final calendarService = ref.read(calendarServiceProvider);
    bool hasPermission = await calendarService.hasPermissions();
    if (!hasPermission) hasPermission = await calendarService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要日历权限才能同步')));
      }
      return;
    }

    final calendarResult = await calendarService.getDefaultCalendar();
    if (calendarResult?.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到可用的日历')));
      }
      return;
    }

    final studentName = _students
        .where((s) => s.id == _selectedStudentId)
        .map((s) => s.name).firstOrNull ?? '';
    final title = '$_selectedSubject - $studentName';
    final description = '家教课程\n学生: $studentName\n科目: $_selectedSubject';
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim() : null;

    int synced = 0;
    for (int i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      final startDate = CalendarService.getNextOccurrence(
          slot.dayOfWeek, slot.startTime.hour, slot.startTime.minute);
      final endDate = startDate.add(Duration(
          hours: slot.endTime.hour - slot.startTime.hour,
          minutes: slot.endTime.minute - slot.startTime.minute));

      // 查找对应的已有记录
      String? existingEventId;
      if (i < _existingSchedules.length) {
        existingEventId = _existingSchedules[i].calendarEventId;
      }

      String? eventId;
      if (existingEventId != null) {
        eventId = await calendarService.updateEvent(
          calendarId: calendarResult!.id!, eventId: existingEventId,
          title: title, startTime: startDate, endTime: endDate,
          description: description, location: location,
          reminderMinutes: _reminderMinutes,
          repeatRule: _repeatRule, repeatEndDate: _repeatEndDate,
        );
      } else {
        eventId = await calendarService.createEvent(
          calendarId: calendarResult!.id!,
          title: title, startTime: startDate, endTime: endDate,
          description: description, location: location,
          reminderMinutes: _reminderMinutes,
          repeatRule: _repeatRule, repeatEndDate: _repeatEndDate,
        );
      }

      // 更新数据库中的 calendarEventId
      if (eventId != null && i < _existingSchedules.length) {
        final repo = ref.read(scheduleRepositoryProvider);
        await repo.updateSchedule(
            _existingSchedules[i].copyWith(calendarEventId: eventId));
        synced++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已同步 $synced 个时间段到日历')));
    }
  }

  // ========== 保存 ==========

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择学生')));
      return;
    }

    // 检查时间段
    for (final slot in _timeSlots) {
      final startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMinutes = slot.endTime.hour * 60 + slot.endTime.minute;
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${slot.dayName} 结束时间必须晚于开始时间')));
        return;
      }
    }

    // 检查同一天的时间段是否交叉
    final Map<int, List<TimeSlot>> byDay = {};
    for (final slot in _timeSlots) {
      byDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }
    for (final entry in byDay.entries) {
      final slots = entry.value;
      if (slots.length < 2) continue;
      slots.sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));
      for (int i = 0; i < slots.length - 1; i++) {
        final aEnd = slots[i].endTime.hour * 60 + slots[i].endTime.minute;
        final bStart = slots[i + 1].startTime.hour * 60 + slots[i + 1].startTime.minute;
        if (aEnd > bStart) {
          final dayName = slots[i].dayName;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$dayName 的时间段有交叉，请调整')));
          }
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(scheduleRepositoryProvider);
      final newGroupId = _groupId ?? const Uuid().v4();

      // 编辑模式：删除旧记录再创建新记录
      if (_isEditing && _groupId != null) {
        await repo.deleteSchedulesByGroup(_groupId!);
      } else if (_isEditing && _existingSchedules.isNotEmpty) {
        // 单条记录编辑（无分组），也转为分组
        for (final s in _existingSchedules) {
          await repo.deleteSchedule(s.id);
        }
      }

      // 创建所有时间段
      final now = DateTime.now();
      final List<ScheduleModel> created = [];
      for (final slot in _timeSlots) {
        final startDT = DateTime(now.year, now.month, now.day,
            slot.startTime.hour, slot.startTime.minute);
        final endDT = DateTime(now.year, now.month, now.day,
            slot.endTime.hour, slot.endTime.minute);

        final id = const Uuid().v4();
        final schedule = ScheduleModel(
          id: id,
          studentId: _selectedStudentId!,
          subject: _selectedSubject,
          dayOfWeek: slot.dayOfWeek,
          startTime: startDT,
          endTime: endDT,
          repeatRule: _repeatRule,
          repeatEndDate: _repeatEndDate,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim() : null,
          isActive: true,
          reminderMinutes: _reminderMinutes,
          scheduleGroupId: _timeSlots.length > 1 ? newGroupId : null,
          biweeklyOffset: _repeatRule == 'biweekly' ? _biweeklyOffset : 0,
          createdAt: now,
        );
        await repo.addSchedule(schedule);
        created.add(schedule);
      }

      _existingSchedules = created;
      _groupId = _timeSlots.length > 1 ? newGroupId : null;

      if (mounted) _showSyncPrompt();
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
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('共 ${_timeSlots.length} 个时间段，是否同步到系统日历？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () { Navigator.pop(context); context.pop(); },
            child: const Text('暂不'),
          ),
          CupertinoDialogAction(
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
    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑课程' : '新建课程'),
        actions: [
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
            // ===== 课程信息 =====
            _SectionHeader(title: '课程信息'),
            _GroupedContainer(children: [
              _PickerField(
                label: '学生',
                value: _students
                    .where((s) => s.id == _selectedStudentId)
                    .map((s) => s.name).firstOrNull,
                icon: CupertinoIcons.person,
                onTap: () => _showStudentPicker(context),
              ),
              _AutocompleteField(
                controller: _subjectController,
                label: '科目',
                options: _availableSubjects,
                onSelected: (v) => _selectedSubject = v,
              ),
              _InputField(
                icon: CupertinoIcons.location,
                label: '地点',
                controller: _locationController,
                placeholder: '选填',
                isLast: true,
              ),
            ]),

            // ===== 时间段 =====
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: '上课时间'),
                GestureDetector(
                  onTap: _addTimeSlot,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add_circled,
                          size: 20, color: IosColors.systemBlue),
                      const SizedBox(width: 4),
                      Text('添加时段',
                          style: TextStyle(
                              fontSize: 14,
                              color: IosColors.systemBlue,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            _GroupedContainer(
              children: [
                for (int i = 0; i < _timeSlots.length; i++) ...[
                  _TimeSlotRow(
                    slot: _timeSlots[i],
                    onEdit: () => _editTimeSlot(i),
                    onDelete: _timeSlots.length > 1
                        ? () => _removeTimeSlot(i)
                        : null,
                    isLast: i == _timeSlots.length - 1,
                  ),
                ],
              ],
            ),

            // ===== 重复规则 =====
            const SizedBox(height: 20),
            _SectionHeader(title: '重复与提醒'),
            _GroupedContainer(children: [
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Text('单次', style: TextStyle(fontSize: 13))),
                        'weekly': Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Text('每周', style: TextStyle(fontSize: 13))),
                        'biweekly': Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child:
                                Text('双周', style: TextStyle(fontSize: 13))),
                      },
                      onValueChanged: (v) {
                        if (v != null) setState(() => _repeatRule = v);
                      },
                    ),
                  ],
                ),
              ),
              if (_repeatRule == 'biweekly') ...[
                Divider(height: 0.5, indent: 14,
                    color: IosColors.separator(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('起始周',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: IosColors.secondaryLabel(context))),
                      const SizedBox(height: 10),
                      CupertinoSlidingSegmentedControl<int>(
                        groupValue: _biweeklyOffset,
                        children: const {
                          0: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Text('从本周开始',
                                  style: TextStyle(fontSize: 13))),
                          1: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Text('从下周开始',
                                  style: TextStyle(fontSize: 13))),
                        },
                        onValueChanged: (v) {
                          if (v != null) setState(() => _biweeklyOffset = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              Divider(height: 0.5, indent: 14,
                  color: IosColors.separator(context)),
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
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _repeatEndDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && mounted) {
                      setState(() => _repeatEndDate = date);
                    }
                  },
                  trailing: _repeatEndDate != null
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _repeatEndDate = null),
                          child: const Icon(
                              CupertinoIcons.clear_circled,
                              size: 22,
                              color: IosColors.systemGray),
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
                      child: Text(s.name,
                          style: const TextStyle(fontSize: 17))))
                  .toList(),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IosColors.secondaryLabel(context))),
      );
}

class _GroupedContainer extends StatelessWidget {
  final List<Widget> children;
  const _GroupedContainer({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: IosColors.secondaryBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isLast;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailing,
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
      if (!isLast)
        Divider(
            height: 0.5, indent: 46, color: IosColors.separator(context)),
    ]);
  }
}

class _InputField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool isLast;

  const _InputField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.placeholder,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 20, color: IosColors.systemBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              style: const TextStyle(fontSize: 15),
              padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: null,
            ),
          ),
        ]),
      ),
      if (!isLast)
        Divider(
            height: 0.5, indent: 46, color: IosColors.separator(context)),
    ]);
  }
}

// 时间段行
class _TimeSlotRow extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final bool isLast;

  const _TimeSlotRow({
    required this.slot,
    required this.onEdit,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: IosColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(slot.dayName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: IosColors.systemBlue)),
            ),
            const SizedBox(width: 14),
            Text(slot.timeRange,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Icon(CupertinoIcons.minus_circle,
                    size: 22, color: IosColors.systemRed),
              ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.right_chevron,
                size: 16, color: IosColors.tertiaryLabel(context)),
          ]),
        ),
      ),
      if (!isLast)
        Divider(
            height: 0.5, indent: 14, color: IosColors.separator(context)),
    ]);
  }
}

// 自动补全字段
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
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          const Icon(CupertinoIcons.book,
              size: 20, color: IosColors.systemBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 16),
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return options;
                return options.where((s) => s
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: onSelected,
              fieldViewBuilder:
                  (context, ctrl, focusNode, onFieldSubmitted) {
                if (controller.text.isNotEmpty &&
                    ctrl.text != controller.text) {
                  ctrl.text = controller.text;
                }
                return CupertinoTextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  placeholder: '选择或输入科目',
                  style: const TextStyle(fontSize: 15),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0, vertical: 8),
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
        ]),
      ),
      Divider(
          height: 0.5, indent: 46, color: IosColors.separator(context)),
    ]);
  }
}
