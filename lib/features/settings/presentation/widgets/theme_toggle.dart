import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../../../config/theme/color_schemes.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            themeMode == ThemeMode.dark
                ? CupertinoIcons.moon_fill
                : CupertinoIcons.sun_max_fill,
            size: 22,
            color: IosColors.systemBlue,
          ),
          const SizedBox(width: 12),
          const Text('主题模式', style: TextStyle(fontSize: 15)),
          const Spacer(),
          CupertinoSlidingSegmentedControl<ThemeMode>(
            groupValue: themeMode,
            children: const {
              ThemeMode.system: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('自动', style: TextStyle(fontSize: 13)),
              ),
              ThemeMode.light: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('浅色', style: TextStyle(fontSize: 13)),
              ),
              ThemeMode.dark: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('深色', style: TextStyle(fontSize: 13)),
              ),
            },
            onValueChanged: (v) {
              if (v != null) ref.read(themeModeProvider.notifier).state = v;
            },
          ),
        ],
      ),
    );
  }
}
