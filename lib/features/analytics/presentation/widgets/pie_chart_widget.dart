import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme/color_schemes.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const PieChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();
    final total = data.values.fold<int>(0, (sum, v) => sum + v);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = AppColors.subjectColor(item.key);
                final percentage = (item.value / total * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: color,
                  value: item.value.toDouble(),
                  title: '$percentage%',
                  titleStyle: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 60,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((entry) {
            final color = AppColors.subjectColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
