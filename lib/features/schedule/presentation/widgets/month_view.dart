import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    // Calculate number of rows needed
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
            .where((s) => s.dayOfWeek == date.weekday)
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
                        return Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            schedule.subject,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
