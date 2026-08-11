import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../providers/student_providers.dart';

class StudentSearchBar extends ConsumerStatefulWidget {
  const StudentSearchBar({super.key});

  @override
  ConsumerState<StudentSearchBar> createState() => _StudentSearchBarState();
}

class _StudentSearchBarState extends ConsumerState<StudentSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: IosColors.tertiaryBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(CupertinoIcons.search,
                size: 18, color: IosColors.systemGray),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '搜索学生',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: IosColors.tertiaryLabel(context),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                ref.read(studentSearchProvider.notifier).state = value;
              },
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(studentSearchProvider.notifier).state = '';
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10, left: 6),
                child: Icon(CupertinoIcons.clear_circled_solid,
                    size: 18, color: IosColors.systemGray),
              ),
            ),
        ],
      ),
    );
  }
}
