import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../config/theme/color_schemes.dart';
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
                backgroundColor: IosColors.systemBackground(context),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 15,
                        color: IosColors.secondaryLabel(context),
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
          loading: () => const Center(
            child: CupertinoActivityIndicator(radius: 14),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.exclamationmark_circle,
                    size: 48, color: IosColors.systemRed),
                const SizedBox(height: 16),
                Text('加载失败',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(e.toString(),
                    style: TextStyle(
                        color: IosColors.secondaryLabel(context)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                CupertinoButton.filled(
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
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }
}
