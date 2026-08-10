import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.person_add,
                  label: '添加学生',
                  color: theme.colorScheme.primary,
                  onTap: () => context.go('/students/add'),
                ),
                _ActionButton(
                  icon: Icons.add_circle,
                  label: '新建课程',
                  color: theme.colorScheme.tertiary,
                  onTap: () => context.go('/schedule/add'),
                ),
                _ActionButton(
                  icon: Icons.note_add,
                  label: '课程记录',
                  color: theme.colorScheme.secondary,
                  onTap: () => context.go('/schedule'),
                ),
                _ActionButton(
                  icon: Icons.bar_chart,
                  label: '数据统计',
                  color: theme.colorScheme.error,
                  onTap: () => context.go('/analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
