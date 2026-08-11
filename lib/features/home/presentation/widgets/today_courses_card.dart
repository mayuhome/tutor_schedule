import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../providers/home_providers.dart';

class TodayCoursesCard extends ConsumerWidget {
  const TodayCoursesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(todayCoursesProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('M月d日 EEEE', 'zh_CN').format(now);

    return Container(
      decoration: BoxDecoration(
        color: IosColors.systemBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.calendar_today,
                  color: IosColors.systemBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日课程',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/schedule'),
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    fontSize: 15,
                    color: IosColors.systemBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.checkmark_circle,
                            size: 44,
                            color: IosColors.tertiaryLabel(context)),
                        const SizedBox(height: 12),
                        Text(
                          '今天没有课程安排',
                          style: TextStyle(
                            fontSize: 15,
                            color: IosColors.secondaryLabel(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPast
                            ? IosColors.tertiaryBackground(context)
                            : IosColors.secondaryBackground(context),
                        borderRadius: BorderRadius.circular(10),
                        border: isOngoing
                            ? Border.all(
                                color: IosColors.systemBlue, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                startTime.timeString,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isPast
                                      ? IosColors.tertiaryLabel(context)
                                      : IosColors.systemBlue,
                                ),
                              ),
                              Text(
                                endTime.timeString,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: IosColors.tertiaryLabel(context),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: IosColors.separator(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.subject,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: isPast
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isPast
                                        ? IosColors.tertiaryLabel(context)
                                        : IosColors.label(context),
                                  ),
                                ),
                                if (course.location != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.location,
                                          size: 12,
                                          color:
                                              IosColors.tertiaryLabel(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course.location!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: IosColors.tertiaryLabel(
                                                context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isOngoing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: IosColors.systemBlue
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '进行中',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: IosColors.systemBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (courses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '共 ${courses.length} 节课',
                        style: TextStyle(
                          fontSize: 13,
                          color: IosColors.secondaryLabel(context),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (e, _) => Center(
              child: Text('加载失败',
                  style: TextStyle(color: IosColors.systemRed)),
            ),
          ),
        ],
      ),
    );
  }
}
