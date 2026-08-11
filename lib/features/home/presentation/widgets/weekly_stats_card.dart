import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../providers/home_providers.dart';

class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);

    return Container(
      decoration: BoxDecoration(
        color: IosColors.secondaryBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周概览',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                _StatItem(
                  icon: CupertinoIcons.clock,
                  label: '授课时长',
                  value: '${stats.totalHours.toStringAsFixed(1)}h',
                  color: IosColors.systemBlue,
                ),
                _StatItem(
                  icon: CupertinoIcons.person_2,
                  label: '学生人数',
                  value: '${stats.studentCount}',
                  color: IosColors.systemPurple,
                ),
                _StatItem(
                  icon: CupertinoIcons.calendar,
                  label: '课程数',
                  value: '${stats.courseCount}',
                  color: IosColors.systemGreen,
                ),
              ],
            ),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: IosColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
