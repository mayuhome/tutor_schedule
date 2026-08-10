import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/analytics_repository.dart';

class BarChartWidget extends ConsumerWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);

    return dailyStatsAsync.when(
      data: (stats) {
        final maxY = stats.fold<int>(
              0,
              (max, s) => s.duration > max ? s.duration : max,
            ) /
            60.0;
        final adjustedMax = maxY < 1 ? 1.0 : (maxY * 1.2);

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: adjustedMax,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toStringAsFixed(1)}h',
                    theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < stats.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('E').format(stats[index].date),
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(0)}h',
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: stats.asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;
              final hours = stat.duration / 60.0;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: hours,
                    color: theme.colorScheme.primary,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}
