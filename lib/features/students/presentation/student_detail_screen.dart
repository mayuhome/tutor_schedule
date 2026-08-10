import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_providers.dart';
import '../data/models/student_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../config/theme/color_schemes.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final theme = Theme.of(context);

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('学生详情')),
            body: const EmptyState(
              icon: Icons.person_off,
              title: '学生不存在',
            ),
          );
        }
        return _StudentDetailContent(student: student);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('学生详情')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('学生详情')),
        body: Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _StudentDetailContent extends ConsumerWidget {
  final StudentModel student;

  const _StudentDetailContent({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/students/${student.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: '删除学生',
                content: '确定要删除 ${student.name} 吗？此操作不可撤销。',
                confirmText: '删除',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await ref.read(studentRepositoryProvider).deleteStudent(student.id);
                if (context.mounted) context.go('/students');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像和基本信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.subjectColor(student.name),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.grade,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (student.school != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              student.school!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 科目标签
            if (student.subjects.isNotEmpty) ...[
              Text(
                '科目',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: student.subjects.map((subject) {
                  return Chip(
                    label: Text(subject),
                    backgroundColor: AppColors.subjectColor(subject).withOpacity(0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 联系方式
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '联系方式',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (student.phone != null)
                      _InfoRow(
                        icon: Icons.phone,
                        label: '学生电话',
                        value: student.phone!,
                      ),
                    if (student.parentPhone != null)
                      _InfoRow(
                        icon: Icons.contact_phone,
                        label: '家长电话',
                        value: student.parentPhone!,
                      ),
                    if (student.phone == null && student.parentPhone == null)
                      Text(
                        '暂无联系方式',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 备注
            if (student.notes != null && student.notes!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '备注',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(student.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 标签
            if (student.tags.isNotEmpty) ...[
              Text(
                '标签',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: student.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    avatar: const Icon(Icons.label, size: 16),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
