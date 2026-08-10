import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../providers/home_providers.dart';
import 'widgets/today_courses_card.dart';
import 'widgets/weekly_stats_card.dart';
import 'widgets/quick_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年M月d日', 'zh_CN').format(now);
    final demoDataSeeded = ref.watch(demoDataSeededProvider);

    return Scaffold(
      body: SafeArea(
        child: demoDataSeeded.when(
          data: (_) => CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const TodayCoursesCard(),
                    const SizedBox(height: 16),
                    const WeeklyStatsCard(),
                    const SizedBox(height: 16),
                    const QuickActions(),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          ),
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载中...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(demoDataSeededProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了，注意休息';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了，注意休息';
  }
}
