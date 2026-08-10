import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_providers.dart';
import 'widgets/student_card.dart';
import 'widgets/student_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(filteredStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学生管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.go('/students/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: StudentSearchBar(),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: '还没有学生',
                    subtitle: '点击右上角添加第一个学生',
                    actionLabel: '添加学生',
                    onAction: () => context.go('/students/add'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return StudentCard(
                      student: student,
                      onTap: () => context.go('/students/${student.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
