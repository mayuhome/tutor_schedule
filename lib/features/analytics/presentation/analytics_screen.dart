import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/color_schemes.dart';
import '../data/analytics_repository.dart';
import 'widgets/stats_card.dart';
import 'widgets/pie_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: const Text('数据分析'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // iOS 分段控件
          Container(
            decoration: BoxDecoration(
              color: IosColors.tertiaryBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: selectedPeriod,
              children: const {
                'week': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('本周', style: TextStyle(fontSize: 13))),
                'month': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('本月', style: TextStyle(fontSize: 13))),
                'year': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('本年', style: TextStyle(fontSize: 13))),
              },
              onValueChanged: (v) {
                if (v != null) {
                  ref.read(selectedPeriodProvider.notifier).state = v;
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          analyticsAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: StatsCard(
                      icon: CupertinoIcons.clock,
                      label: '总课时',
                      value: '${data.totalHours.toStringAsFixed(1)}h',
                      color: IosColors.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: CupertinoIcons.person_2,
                      label: '学生数',
                      value: '${data.totalStudents}',
                      color: IosColors.systemPurple,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: StatsCard(
                      icon: CupertinoIcons.calendar,
                      label: '课程数',
                      value: '${data.totalCourses}',
                      color: IosColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: CupertinoIcons.money_dollar_circle,
                      label: '预估收入',
                      value: '¥${data.estimatedIncome.toStringAsFixed(0)}',
                      color: IosColors.systemOrange,
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                if (data.subjectDistribution.isNotEmpty) ...[
                  _SectionHeader(title: '科目分布'),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: IosColors.secondaryBackground(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: PieChartWidget(data: data.subjectDistribution),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(title: '每日课时'),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: IosColors.secondaryBackground(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const BarChartWidget(),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                  child: Text('加载失败: $e',
                      style: const TextStyle(color: IosColors.systemRed))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: IosColors.secondaryLabel(context)));
  }
}
