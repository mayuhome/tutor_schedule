import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../../../app.dart';
import '../../../../core/database/daos/student_dao.dart';
import '../../providers/schedule_providers.dart';
import '../../data/models/schedule_model.dart';

class WeekView extends ConsumerStatefulWidget {
  const WeekView({super.key});

  @override
  ConsumerState<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  late DateTime _weekStart;
  Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _weekStart = DateTime.now().startOfWeek;
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

  /// 判断双周课程是否在本周显示
  bool _shouldShowBiweekly(ScheduleModel schedule) {
    if (schedule.repeatRule != 'biweekly') return true;
    final created = schedule.createdAt.startOfWeek;
    final current = _weekStart;
    final weekDiff = current.difference(created).inDays ~/ 7;
    final offset = schedule.biweeklyOffset;
    return (weekDiff + offset) % 2 == 0;
  }

  /// 获取某天的日期对象
  DateTime _dateForDay(int dayOfWeek) {
    return _weekStart.add(Duration(days: dayOfWeek - 1));
  }

  Future<void> _showActionSheet(ScheduleModel schedule) async {
    final calendarService = ref.read(calendarServiceProvider);
    final repo = ref.read(scheduleRepositoryProvider);
    final dateForSlot = _dateForDay(schedule.dayOfWeek ?? 1);
    final isCancelled = schedule.isCancelledOn(dateForSlot);

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
                await _cancelInstance(schedule, dateForSlot, calendarService, repo);
              },
            ),
          if (isCancelled)
            CupertinoActionSheetAction(
              child: const Text('恢复本次'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _restoreInstance(schedule, dateForSlot, repo);
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

  /// 取消单次实例
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

  /// 恢复单次实例
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

  /// 删除整个课程
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
      // 如果有分组，删除整个组
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
        // 周导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _weekStart = _weekStart.subtract(const Duration(days: 7));
                  });
                },
              ),
              Text(
                '${_weekStart.month}月${_weekStart.day}日 - ${_weekStart.add(const Duration(days: 6)).month}月${_weekStart.add(const Duration(days: 6)).day}日',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _weekStart = _weekStart.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),
        // 星期标题行
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(7, (index) {
              final date = _weekStart.add(Duration(days: index));
              final isToday = date.isToday;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date.shortWeekdayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isToday
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // 课程网格
        Expanded(
          child: schedulesAsync.when(
            data: (schedules) {
              return SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(7, (index) {
                    final dayOfWeek = index + 1;
                    final dateForDay = _dateForDay(dayOfWeek);
                    final daySchedules = schedules
                        .where((s) =>
                            s.dayOfWeek == dayOfWeek &&
                            _shouldShowBiweekly(s) &&
                            !s.isCancelledOn(dateForDay))
                        .toList();
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Column(
                          children: daySchedules.map((schedule) {
                            return _ScheduleItem(
                              schedule: schedule,
                              studentName:
                                  _studentNames[schedule.studentId] ?? '未知',
                              onTap: () => _showActionSheet(schedule),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final ScheduleModel schedule;
  final String studentName;
  final VoidCallback onTap;

  const _ScheduleItem({
    required this.schedule,
    required this.studentName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.subjectColor(schedule.subject);
    final isBiweekly = schedule.repeatRule == 'biweekly';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule.subject,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isBiweekly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '双',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              studentName,
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
