import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return SearchBar(
      controller: _controller,
      hintText: '搜索学生姓名、年级、科目...',
      leading: const Icon(Icons.search),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              ref.read(studentSearchProvider.notifier).state = '';
            },
          ),
      ],
      onChanged: (value) {
        ref.read(studentSearchProvider.notifier).state = value;
      },
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
