import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_repository.dart';
import 'widgets/stats_card.dart';
import 'widgets/pie_chart_widget.dart';
import 'widgets/bar_chart_widget.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            onSelected: (value) {
              // TODO: Export functionality
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Text('导出 CSV'),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Text('导出 Excel'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 时间段选择
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'week', label: Text('本周')),
              ButtonSegment(value: 'month', label: Text('本月')),
              ButtonSegment(value: 'year', label: Text('本年')),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (values) {
              ref.read(selectedPeriodProvider.notifier).state = values.first;
            },
          ),
          const SizedBox(height: 24),

          // 统计卡片
          analyticsAsync.when(
            data: (data) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        icon: Icons.access_time,
                        label: '总课时',
                        value: '${data.totalHours.toStringAsFixed(1)}h',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        icon: Icons.people,
                        label: '学生数',
                        value: '${data.totalStudents}',
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        icon: Icons.calendar_today,
                        label: '课程数',
                        value: '${data.totalCourses}',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        icon: Icons.attach_money,
                        label: '预估收入',
                        value: '¥${data.estimatedIncome.toStringAsFixed(0)}',
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 科目分布饼图
                if (data.subjectDistribution.isNotEmpty) ...[
                  Text(
                    '科目分布',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChartWidget(
                      data: data.subjectDistribution,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 每日课时柱状图
                Text(
                  '每日课时',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  height: 200,
                  child: BarChartWidget(),
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Text('加载失败: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
