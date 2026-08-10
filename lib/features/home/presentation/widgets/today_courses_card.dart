import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../providers/home_providers.dart';

class TodayCoursesCard extends ConsumerWidget {
  const TodayCoursesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(todayCoursesProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('M月d日 EEEE', 'zh_CN').format(now);

    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日课程',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/schedule'),
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '今天没有课程安排',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => context.go('/schedule/add'),
                            child: const Text('添加课程'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...courses.map((course) {
                      final startTime = course.startTime;
                      final endTime = course.endTime;
                      final isPast = endTime.isBefore(now);
                      final isOngoing =
                          startTime.isBefore(now) && endTime.isAfter(now);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isPast
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: isOngoing
                              ? Border.all(
                                  color: theme.colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                startTime.timeString,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPast
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                endTime.timeString,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            course.subject,
                            style: TextStyle(
                              decoration:
                                  isPast ? TextDecoration.lineThrough : null,
                              color: isPast
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          subtitle: course.location != null
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(course.location!),
                                  ],
                                )
                              : null,
                          trailing: isOngoing
                              ? Chip(
                                  label: Text(
                                    '进行中',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                        ),
                      );
                    }),
                    if (courses.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '共 ${courses.length} 节课',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text('加载失败: $e'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
