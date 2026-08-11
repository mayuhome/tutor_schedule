import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app.dart';
import '../../../core/database/app_database.dart';
import '../providers/settings_providers.dart';
import 'widgets/theme_toggle.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyRate = ref.watch(hourlyRateProvider);
    final reminderEnabled = ref.watch(reminderEnabledProvider);
    final defaultReminderMinutes = ref.watch(defaultReminderMinutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: '外观'),
          const ThemeToggle(),
          const Divider(height: 1),

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

          _SectionHeader(title: '费用设置'),
          ListTile(
            title: const Text('默认课时费'),
            subtitle: Text('¥${hourlyRate.toStringAsFixed(0)}/小时（未单独设置时的默认值）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHourlyRateDialog(context, ref, hourlyRate),
          ),
          const Divider(height: 1),

          _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出所有数据为 JSON 文件'),
            onTap: () => _backupData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件导入数据'),
            onTap: () => _restoreData(context, ref),
          ),
          const Divider(height: 1),

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
        title: const Text('设置默认课时费'),
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

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备份数据'),
        content: const Text('将导出所有学生、课程记录、排课、进度和费用数据为 JSON 文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开始备份'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final db = ref.read(databaseProvider);

      final students = await db.select(db.students).get();
      final records = await db.select(db.courseRecords).get();
      final schedules = await db.select(db.schedules).get();
      final progress = await db.select(db.progressEntries).get();
      final fees = await db.select(db.courseFees).get();

      final backup = {
        'version': 3,
        'createdAt': DateTime.now().toIso8601String(),
        'students': students.map((s) => {
              'id': s.id,
              'name': s.name,
              'grade': s.grade,
              'school': s.school,
              'phone': s.phone,
              'parentPhone': s.parentPhone,
              'subjects': s.subjects,
              'tags': s.tags,
              'notes': s.notes,
              'avatarColor': s.avatarColor,
              'createdAt': s.createdAt.toIso8601String(),
              'updatedAt': s.updatedAt.toIso8601String(),
            }),
        'courseRecords': records.map((r) => {
              'id': r.id,
              'studentId': r.studentId,
              'subject': r.subject,
              'date': r.date.toIso8601String(),
              'duration': r.duration,
              'content': r.content,
              'homework': r.homework,
              'rating': r.rating,
              'summary': r.summary,
              'notes': r.notes,
              'fee': r.fee,
              'attachments': r.attachments,
              'createdAt': r.createdAt.toIso8601String(),
            }),
        'schedules': schedules.map((s) => {
              'id': s.id,
              'studentId': s.studentId,
              'subject': s.subject,
              'dayOfWeek': s.dayOfWeek,
              'startTime': s.startTime.toIso8601String(),
              'endTime': s.endTime.toIso8601String(),
              'repeatRule': s.repeatRule,
              'repeatEndDate': s.repeatEndDate?.toIso8601String(),
              'location': s.location,
              'isActive': s.isActive,
              'reminderMinutes': s.reminderMinutes,
              'createdAt': s.createdAt.toIso8601String(),
            }),
        'progressEntries': progress.map((p) => {
              'id': p.id,
              'studentId': p.studentId,
              'subject': p.subject,
              'topic': p.topic,
              'masteryLevel': p.masteryLevel,
              'notes': p.notes,
              'createdAt': p.createdAt.toIso8601String(),
              'updatedAt': p.updatedAt.toIso8601String(),
            }),
        'courseFees': fees.map((f) => {
              'id': f.id,
              'studentId': f.studentId,
              'subject': f.subject,
              'feePerHour': f.feePerHour,
              'createdAt': f.createdAt.toIso8601String(),
            }),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final fileName =
          'tutor_schedule_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: '家教日程管家 数据备份',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份完成')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text(
          '⚠️ 此操作将清空当前所有数据并从备份文件导入。\n\n建议先备份当前数据。\n\n确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonStr = await file.readAsString(encoding: utf8);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null) {
        throw Exception('无效的备份文件');
      }

      if (!context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final db = ref.read(databaseProvider);

      await db.transaction(() async {
        // 清空现有数据（注意顺序，先删有外键引用的表）
        await db.delete(db.courseRecords).go();
        await db.delete(db.schedules).go();
        await db.delete(db.progressEntries).go();
        await db.delete(db.courseFees).go();
        await db.delete(db.students).go();

        // 恢复学生
        final studentsList = data['students'] as List? ?? [];
        for (final s in studentsList.cast<Map<String, dynamic>>()) {
          await db.into(db.students).insert(
            StudentsCompanion.insert(
              id: s['id'] as String,
              name: s['name'] as String,
              grade: s['grade'] as String,
              school: Value(s['school'] as String?),
              phone: Value(s['phone'] as String?),
              parentPhone: Value(s['parentPhone'] as String?),
              subjects: Value((s['subjects'] as String?) ?? '[]'),
              tags: Value((s['tags'] as String?) ?? '[]'),
              notes: Value(s['notes'] as String?),
              avatarColor: Value(s['avatarColor'] as String?),
            ),
          );
        }

        // 恢复课程记录
        final recordsList = data['courseRecords'] as List? ?? [];
        for (final r in recordsList.cast<Map<String, dynamic>>()) {
          await db.into(db.courseRecords).insert(
            CourseRecordsCompanion.insert(
              id: r['id'] as String,
              studentId: r['studentId'] as String,
              subject: r['subject'] as String,
              date: DateTime.parse(r['date'] as String),
              duration: r['duration'] as int,
              content: r['content'] as String,
              homework: Value(r['homework'] as String?),
              rating: Value((r['rating'] as int?) ?? 3),
              summary: Value(r['summary'] as String?),
              notes: Value(r['notes'] as String?),
              fee: Value((r['fee'] as num?)?.toDouble()),
              attachments:
                  Value((r['attachments'] as String?) ?? '[]'),
            ),
          );
        }

        // 恢复排课
        final schedulesList = data['schedules'] as List? ?? [];
        for (final s in schedulesList.cast<Map<String, dynamic>>()) {
          await db.into(db.schedules).insert(
            SchedulesCompanion.insert(
              id: s['id'] as String,
              studentId: s['studentId'] as String,
              subject: s['subject'] as String,
              startTime: DateTime.parse(s['startTime'] as String),
              endTime: DateTime.parse(s['endTime'] as String),
              dayOfWeek: Value(s['dayOfWeek'] as int?),
              repeatRule: Value((s['repeatRule'] as String?) ?? 'none'),
              repeatEndDate: Value(s['repeatEndDate'] != null
                  ? DateTime.parse(s['repeatEndDate'] as String)
                  : null),
              location: Value(s['location'] as String?),
              isActive: Value((s['isActive'] as bool?) ?? true),
              reminderMinutes:
                  Value((s['reminderMinutes'] as int?) ?? 30),
            ),
          );
        }

        // 恢复学习进度
        final progressList = data['progressEntries'] as List? ?? [];
        for (final p in progressList.cast<Map<String, dynamic>>()) {
          await db.into(db.progressEntries).insert(
            ProgressEntriesCompanion.insert(
              id: p['id'] as String,
              studentId: p['studentId'] as String,
              subject: p['subject'] as String,
              topic: p['topic'] as String,
              masteryLevel: Value((p['masteryLevel'] as int?) ?? 3),
              notes: Value(p['notes'] as String?),
            ),
          );
        }

        // 恢复课程费用（备份版本 < 3 时可能没有此数据）
        final feesList = data['courseFees'] as List? ?? [];
        for (final f in feesList.cast<Map<String, dynamic>>()) {
          await db.into(db.courseFees).insert(
            CourseFeesCompanion.insert(
              id: f['id'] as String,
              studentId: f['studentId'] as String,
              subject: f['subject'] as String,
              feePerHour: (f['feePerHour'] as num).toDouble(),
            ),
          );
        }
      });

      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据恢复成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
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
