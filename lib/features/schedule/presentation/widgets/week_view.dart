import 'package:flutter/material.dart';
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
                    final daySchedules = schedules
                        .where((s) => s.dayOfWeek == dayOfWeek)
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
                              onTap: () => context
                                  .go('/schedule/${schedule.id}/edit'),
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

    return InkWell(
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
            Text(
              schedule.subject,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
