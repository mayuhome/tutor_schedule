import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/color_schemes.dart';
import '../../../app.dart';
import '../../../core/database/daos/student_dao.dart';
import '../providers/schedule_providers.dart';
import '../data/models/schedule_model.dart';

class ScheduleListScreen extends ConsumerStatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  ConsumerState<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends ConsumerState<ScheduleListScreen> {
  Map<String, String> _studentNames = {};
  String _filter = 'all'; // all, active, completed, inactive

  @override
  void initState() {
    super.initState();
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

  List<ScheduleModel> _applyFilter(List<ScheduleModel> schedules) {
    // 按 groupId 分组，只显示每组的第一个（避免重复显示多个时间段）
    final Map<String?, ScheduleModel> groupFirst = {};
    for (final s in schedules) {
      if (!groupFirst.containsKey(s.scheduleGroupId ?? s.id)) {
        groupFirst[s.scheduleGroupId ?? s.id] = s;
      }
    }
    final unique = groupFirst.values.toList();

    switch (_filter) {
      case 'active':
        return unique.where((s) => s.isActive && !s.isCompleted).toList();
      case 'completed':
        return unique.where((s) => s.isCompleted).toList();
      case 'inactive':
        return unique.where((s) => !s.isActive).toList();
      default:
        return unique;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(allSchedulesIncludingInactiveProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('课程管理'),
        trailing: GestureDetector(
          onTap: () => context.go('/schedule/add'),
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 筛选器
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _filter,
                children: const {
                  'all': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('全部', style: TextStyle(fontSize: 13)),
                  ),
                  'active': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('进行中', style: TextStyle(fontSize: 13)),
                  ),
                  'completed': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('已完成', style: TextStyle(fontSize: 13)),
                  ),
                  'inactive': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('已停用', style: TextStyle(fontSize: 13)),
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _filter = v);
                },
              ),
            ),
            // 课程列表
            Expanded(
              child: schedulesAsync.when(
                data: (schedules) {
                  final filtered = _applyFilter(schedules);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.calendar_badge_minus,
                              size: 48, color: IosColors.systemGray),
                          const SizedBox(height: 12),
                          Text('暂无课程',
                              style: TextStyle(
                                  color: IosColors.secondaryLabel(context),
                                  fontSize: 15)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 0.5,
                      indent: 52,
                      color: IosColors.separator(context),
                    ),
                    itemBuilder: (context, index) {
                      final schedule = filtered[index];
                      return _ScheduleListItem(
                        schedule: schedule,
                        studentName: _studentNames[schedule.studentId] ?? '未知',
                        onTap: () => _showActionSheet(schedule),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActionSheet(ScheduleModel schedule) async {
    final calendarService = ref.read(calendarServiceProvider);
    final repo = ref.read(scheduleRepositoryProvider);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(schedule.subject),
        message: Text(
          '${_studentNames[schedule.studentId] ?? "未知"} · ${schedule.dayName} ${schedule.timeRange}',
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('编辑课程'),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/schedule/${schedule.id}/edit');
            },
          ),
          if (schedule.isActive)
            CupertinoActionSheetAction(
              child: const Text('停用课程'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _toggleActive(schedule, false, repo);
              },
            ),
          if (!schedule.isActive)
            CupertinoActionSheetAction(
              child: const Text('启用课程'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _toggleActive(schedule, true, repo);
              },
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('删除课程'),
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

  Future<void> _toggleActive(
    ScheduleModel schedule,
    bool active,
    dynamic repo,
  ) async {
    try {
      if (schedule.isInGroup) {
        final group = await repo.getSchedulesByGroup(schedule.scheduleGroupId!);
        for (final s in group) {
          await repo.updateSchedule(s.copyWith(isActive: active));
        }
      } else {
        await repo.updateSchedule(schedule.copyWith(isActive: active));
      }
      ref.invalidate(allSchedulesIncludingInactiveProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(active ? '已启用' : '已停用')),
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
      ref.invalidate(allSchedulesIncludingInactiveProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
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
}

class _ScheduleListItem extends StatelessWidget {
  final ScheduleModel schedule;
  final String studentName;
  final VoidCallback onTap;

  const _ScheduleListItem({
    required this.schedule,
    required this.studentName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.subjectColor(schedule.subject);
    final statusColor = schedule.isActive
        ? (schedule.isCompleted ? Colors.orange : Colors.green)
        : Colors.grey;
    final statusText = schedule.statusText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // 科目色块
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: schedule.isActive
                                ? null
                                : IosColors.secondaryLabel(context),
                            decoration: schedule.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$studentName · ${schedule.dayName} ${schedule.timeRange}',
                    style: TextStyle(
                      fontSize: 13,
                      color: IosColors.secondaryLabel(context),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        schedule.repeatRuleName,
                        style: TextStyle(
                          fontSize: 12,
                          color: IosColors.tertiaryLabel(context),
                        ),
                      ),
                      if (schedule.isSyncedToCalendar) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            size: 12, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          '已同步日历',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 16, color: IosColors.systemGray),
          ],
        ),
      ),
    );
  }
}
