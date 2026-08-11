import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_providers.dart';
import '../data/models/student_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/color_schemes.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('学生详情')),
            body: const EmptyState(
              icon: CupertinoIcons.person,
              title: '学生不存在',
            ),
          );
        }
        return _StudentDetailContent(student: student);
      },
      loading: () => Scaffold(
        backgroundColor: IosColors.systemBackground(context),
        appBar: AppBar(title: const Text('学生详情')),
        body: const Center(child: CupertinoActivityIndicator()),
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
    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 22),
            onPressed: () => context.go('/students/${student.id}/edit'),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.delete, size: 22,
                color: IosColors.systemRed),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: '删除学生',
                content: '确定要删除 ${student.name} 吗？此操作不可撤销。',
                confirmText: '删除',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await ref
                    .read(studentRepositoryProvider)
                    .deleteStudent(student.id);
                if (context.mounted) context.go('/students');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头像卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: IosColors.secondaryBackground(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.subjectColor(student.name),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(student.grade,
                          style: TextStyle(
                              fontSize: 15,
                              color: IosColors.secondaryLabel(context))),
                      if (student.school != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(student.school!,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      IosColors.tertiaryLabel(context))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 科目标签
          if (student.subjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IosColors.secondaryBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('科目',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: IosColors.secondaryLabel(context))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student.subjects.map((subject) {
                      final color = AppColors.subjectColor(subject);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(subject,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: color)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // 联系方式
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: IosColors.secondaryBackground(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Text('联系方式',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: IosColors.secondaryLabel(context))),
                    ],
                  ),
                ),
                if (student.phone != null)
                  _InfoRow(
                    icon: CupertinoIcons.phone,
                    label: '学生电话',
                    value: student.phone!,
                  ),
                if (student.phone != null && student.parentPhone != null)
                  Divider(
                      height: 0.5,
                      indent: 52,
                      color: IosColors.separator(context)),
                if (student.parentPhone != null)
                  _InfoRow(
                    icon: CupertinoIcons.person,
                    label: '家长电话',
                    value: student.parentPhone!,
                  ),
                if (student.phone == null && student.parentPhone == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text('暂无联系方式',
                        style: TextStyle(
                            fontSize: 15,
                            color: IosColors.tertiaryLabel(context))),
                  ),
              ],
            ),
          ),

          // 备注
          if (student.notes != null && student.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IosColors.secondaryBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('备注',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: IosColors.secondaryLabel(context))),
                  const SizedBox(height: 8),
                  Text(student.notes!,
                      style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],

          // 标签
          if (student.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IosColors.secondaryBackground(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('标签',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: IosColors.secondaryLabel(context))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: IosColors.tertiaryBackground(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.tag,
                                size: 13,
                                color: IosColors.secondaryLabel(context)),
                            const SizedBox(width: 4),
                            Text(tag,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: IosColors.label(context))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: IosColors.systemBlue),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  fontSize: 15, color: IosColors.secondaryLabel(context))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
