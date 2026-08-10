import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../providers/settings_providers.dart';
import 'widgets/theme_toggle.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hourlyRate = ref.watch(hourlyRateProvider);
    final reminderEnabled = ref.watch(reminderEnabledProvider);
    final defaultReminderMinutes = ref.watch(defaultReminderMinutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 外观
          _SectionHeader(title: '外观'),
          const ThemeToggle(),
          const Divider(height: 1),

          // 提醒设置
          _SectionHeader(title: '提醒设置'),
          SwitchListTile(
            title: const Text('启用课程提醒'),
            subtitle: const Text('课前推送本地通知'),
            value: reminderEnabled,
            onChanged: (value) {
              ref.read(reminderEnabledProvider.notifier).state = value;
            },
          ),
          if (reminderEnabled)
            ListTile(
              title: const Text('默认提醒时间'),
              subtitle: Text('$defaultReminderMinutes 分钟前'),
              trailing: DropdownButton<int>(
                value: defaultReminderMinutes,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15分钟')),
                  DropdownMenuItem(value: 30, child: Text('30分钟')),
                  DropdownMenuItem(value: 60, child: Text('1小时')),
                  DropdownMenuItem(value: 120, child: Text('2小时')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(defaultReminderMinutesProvider.notifier).state =
                        value;
                  }
                },
              ),
            ),
          const Divider(height: 1),

          // 费用设置
          _SectionHeader(title: '费用设置'),
          ListTile(
            title: const Text('课时费单价'),
            subtitle: Text('¥${hourlyRate.toStringAsFixed(0)}/小时'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHourlyRateDialog(context, ref, hourlyRate),
          ),
          const Divider(height: 1),

          // 数据管理
          _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出所有数据为 JSON 文件'),
            onTap: () {
              // TODO: Implement backup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从 JSON 文件导入数据'),
            onTap: () {
              // TODO: Implement restore
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复功能开发中')),
              );
            },
          ),
          const Divider(height: 1),

          // 关于
          _SectionHeader(title: '关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('技术栈'),
            subtitle: Text('Flutter + Riverpod + Drift'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showHourlyRateDialog(
      BuildContext context, WidgetRef ref, double currentRate) {
    final controller = TextEditingController(
      text: currentRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置课时费'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '单价（元/小时）',
            prefixText: '¥',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0) {
                ref.read(hourlyRateProvider.notifier).state = rate;
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
