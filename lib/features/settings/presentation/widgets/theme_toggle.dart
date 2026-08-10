import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListTile(
      leading: Icon(
        themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
      ),
      title: const Text('主题模式'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.phone_android, size: 16),
            label: Text('跟随系统'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 16),
            label: Text('浅色'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 16),
            label: Text('深色'),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (values) {
          ref.read(themeModeProvider.notifier).state = values.first;
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
