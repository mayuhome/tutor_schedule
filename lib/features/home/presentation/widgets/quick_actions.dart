import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/color_schemes.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IosColors.secondaryBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '快速操作',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: IosColors.secondaryLabel(context),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              _ActionButton(
                icon: CupertinoIcons.person_add,
                label: '添加学生',
                color: IosColors.systemBlue,
                onTap: () => context.go('/students/add'),
              ),
              _ActionButton(
                icon: CupertinoIcons.add_circled,
                label: '新建课程',
                color: IosColors.systemGreen,
                onTap: () => context.go('/schedule/add'),
              ),
              _ActionButton(
                icon: CupertinoIcons.doc_text,
                label: '课程记录',
                color: IosColors.systemOrange,
                onTap: () => context.go('/schedule'),
              ),
              _ActionButton(
                icon: CupertinoIcons.chart_bar,
                label: '数据统计',
                color: IosColors.systemPurple,
                onTap: () => context.go('/analytics'),
              ),
            ],
          ),
        ],
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: IosColors.label(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
