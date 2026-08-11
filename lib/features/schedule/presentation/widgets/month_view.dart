import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../../../app.dart';
import '../../../../core/database/daos/student_dao.dart';
import '../../providers/schedule_providers.dart';
import '../../data/models/schedule_model.dart';

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  late DateTime _currentMonth;
  Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadStudentNames();
  }

  Future<void> _loadStudentNames() async {
    final db = ref.read(databaseProvider);
    final dao = StudentDao(db);
    final students = await dao.getAllStudents();
    if (mounted) {
      setState(() {
        _studentNames = {for (var s in students) s.id: s.name};
      });
    }
  }

  /// 判断双周课程是否在指定日期所在周显示
  bool _shouldShowBiweekly(ScheduleModel schedule, DateTime date) {
    if (schedule.repeatRule != 'biweekly') return true;
    final created = schedule.createdAt.startOfWeek;
    final target = date.startOfWeek;
    final weekDiff = target.difference(created).inDays ~/ 7;
    final offset = schedule.biweeklyOffset;
    return (weekDiff + offset) % 2 == 0;
  }

  Future<void> _showActionSheet(ScheduleModel schedule, DateTime date) async {
    final calendarService = ref.read(calendarServiceProvider);
    final repo = ref.read(scheduleRepositoryProvider);
    final isCancelled = schedule.isCancelledOn(date);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${schedule.subject} - ${_studentNames[schedule.studentId] ?? "未知"}'),
        message: Text('${schedule.dayName} ${schedule.timeRange}'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('编辑课程'),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/schedule/${schedule.id}/edit');
            },
          ),
          if (!isCancelled)
            CupertinoActionSheetAction(
              child: const Text('取消本次'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _cancelInstance(schedule, date, calendarService, repo);
              },
            ),
          if (isCancelled)
            CupertinoActionSheetAction(
              child: const Text('恢复本次'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _restoreInstance(schedule, date, repo);
              },
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('删除整个课程'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteSchedule(schedule, calendarService, repo);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _cancelInstance(
    ScheduleModel schedule,
    DateTime date,
    dynamic calendarService,
    dynamic repo,
  ) async {
    try {
      final updated = schedule.cancelOnDate(date);
      await repo.updateSchedule(updated);
      ref.invalidate(scheduleListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消本次课程')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _restoreInstance(
    ScheduleModel schedule,
    DateTime date,
    dynamic repo,
  ) async {
    try {
      final updated = schedule.restoreOnDate(date);
      await repo.updateSchedule(updated);
      ref.invalidate(scheduleListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复本次课程')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(
    ScheduleModel schedule,
    dynamic calendarService,
    dynamic repo,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后不可恢复，确定要删除吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (schedule.isSyncedToCalendar) {
        final calendars = await calendarService.getCalendars();
        if (calendars.isNotEmpty) {
          await calendarService.deleteEvent(
            calendars.first.id,
            schedule.calendarEventId!,
          );
        }
      }
      if (schedule.isInGroup) {
        await repo.deleteSchedulesByGroup(schedule.scheduleGroupId!);
      } else {
        await repo.deleteSchedule(schedule.id);
      }
      ref.invalidate(scheduleListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除课程')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedulesAsync = ref.watch(scheduleListProvider);

    return Column(
      children: [
        // 月份导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('yyyy年MM月').format(_currentMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        // 星期标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['一', '二', '三', '四', '五', '六', '日'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // 日历网格
        Expanded(
          child: schedulesAsync.when(
            data: (schedules) {
              return _buildCalendarGrid(schedules);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List<ScheduleModel> schedules) {
    final theme = Theme.of(context);
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday; // 1 = Monday
    final totalDays = lastDay.day;

    final totalCells = firstWeekday - 1 + totalDays;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        if (dayOffset < 0 || dayOffset >= totalDays) {
          return const SizedBox();
        }

        final day = dayOffset + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final isToday = date.isToday;
        final daySchedules = schedules
            .where((s) =>
                s.dayOfWeek == date.weekday &&
                _shouldShowBiweekly(s, date) &&
                !s.isCancelledOn(date))
            .toList();

        return GestureDetector(
          onTap: () {
            ref.read(selectedDateProvider.notifier).state = date;
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : null,
                      color: isToday
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ),
                if (daySchedules.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: daySchedules.length.clamp(0, 3),
                      itemBuilder: (context, i) {
                        final schedule = daySchedules[i];
                        final color = AppColors.subjectColor(schedule.subject);
                        final isBiweekly = schedule.repeatRule == 'biweekly';
                        return GestureDetector(
                          onTap: () => _showActionSheet(schedule, date),
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    schedule.subject,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      color: color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isBiweekly)
                                  Text(
                                    '双',
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (daySchedules.length > 3)
                  Text(
                    '+${daySchedules.length - 3}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
