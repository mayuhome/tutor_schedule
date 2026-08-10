import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../providers/home_providers.dart';

class TodayCoursesCard extends ConsumerWidget {
  const TodayCoursesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(todayCoursesProvider);

    return Card(
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
                Text(
                  '今日课程',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: courses.map((course) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.book,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(course.subject),
                      subtitle: Text(
                        '${course.startTime.timeString} - ${course.endTime.timeString}',
                      ),
                      trailing: course.location != null
                          ? Chip(
                              label: Text(
                                course.location!,
                                style: theme.textTheme.labelSmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('加载失败: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
