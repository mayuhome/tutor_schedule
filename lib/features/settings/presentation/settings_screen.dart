import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/color_schemes.dart';
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
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 外观
          _SectionHeader(title: '外观'),
          _GroupedContainer(children: [
            const ThemeToggle(),
          ]),

          const SizedBox(height: 24),
          _SectionHeader(title: '提醒设置'),
          _GroupedContainer(children: [
            _SwitchRow(
              icon: CupertinoIcons.bell_fill,
              iconColor: IosColors.systemRed,
              label: '课程提醒',
              value: reminderEnabled,
              onChanged: (v) =>
                  ref.read(reminderEnabledProvider.notifier).state = v,
            ),
            if (reminderEnabled) ...[
              Divider(height: 0.5, indent: 50,
                  color: IosColors.separator(context)),
              _PickerRow(
                icon: CupertinoIcons.clock_fill,
                iconColor: IosColors.systemOrange,
                label: '提醒时间',
                value: '$defaultReminderMinutes 分钟前',
                onTap: () => _showReminderPicker(context, ref),
              ),
            ],
          ]),

          const SizedBox(height: 24),
          _SectionHeader(title: '费用设置'),
          _GroupedContainer(children: [
            _PickerRow(
              icon: CupertinoIcons.money_dollar_circle_fill,
              iconColor: IosColors.systemGreen,
              label: '默认课时费',
              value: '¥${hourlyRate.toStringAsFixed(0)}/小时',
              onTap: () => _showHourlyRateDialog(context, ref, hourlyRate),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 24),
          _SectionHeader(title: '数据管理'),
          _GroupedContainer(children: [
            _ActionRow(
              icon: CupertinoIcons.cloud_upload_fill,
              iconColor: IosColors.systemBlue,
              label: '备份数据',
              subtitle: '导出所有数据为 JSON 文件',
              onTap: () => _backupData(context, ref),
            ),
            Divider(height: 0.5, indent: 50,
                color: IosColors.separator(context)),
            _ActionRow(
              icon: CupertinoIcons.cloud_download_fill,
              iconColor: IosColors.systemIndigo,
              label: '恢复数据',
              subtitle: '从备份文件导入数据',
              onTap: () => _restoreData(context, ref),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 24),
          _SectionHeader(title: '关于'),
          _GroupedContainer(children: [
            _InfoRow(label: '版本', value: '1.0.0'),
            Divider(height: 0.5, indent: 14,
                color: IosColors.separator(context)),
            _InfoRow(label: '技术栈', value: 'Flutter + Riverpod + Drift',
                isLast: true),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showReminderPicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 220,
        color: IosColors.secondaryBackground(context),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                child: const Text('完成'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              onSelectedItemChanged: (i) {
                final values = [15, 30, 60, 120];
                ref.read(defaultReminderMinutesProvider.notifier).state =
                    values[i];
              },
              children: const [
                Center(child: Text('15分钟前', style: TextStyle(fontSize: 17))),
                Center(child: Text('30分钟前', style: TextStyle(fontSize: 17))),
                Center(child: Text('1小时前', style: TextStyle(fontSize: 17))),
                Center(child: Text('2小时前', style: TextStyle(fontSize: 17))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showHourlyRateDialog(
      BuildContext context, WidgetRef ref, double currentRate) {
    final controller =
        TextEditingController(text: currentRate.toStringAsFixed(0));
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('设置默认课时费'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('¥', style: TextStyle(fontSize: 16)),
            ),
            suffix: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('/小时',
                  style:
                      TextStyle(fontSize: 14, color: IosColors.systemGray)),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0) {
                ref.read(hourlyRateProvider.notifier).state = rate;
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('备份数据'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('将导出所有学生、课程记录、排课、进度和费用数据。'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
          'id': s.id, 'name': s.name, 'grade': s.grade,
          'school': s.school, 'phone': s.phone, 'parentPhone': s.parentPhone,
          'subjects': s.subjects, 'tags': s.tags, 'notes': s.notes,
          'avatarColor': s.avatarColor,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt.toIso8601String(),
        }),
        'courseRecords': records.map((r) => {
          'id': r.id, 'studentId': r.studentId, 'subject': r.subject,
          'date': r.date.toIso8601String(), 'duration': r.duration,
          'content': r.content, 'homework': r.homework, 'rating': r.rating,
          'summary': r.summary, 'notes': r.notes, 'fee': r.fee,
          'attachments': r.attachments,
          'createdAt': r.createdAt.toIso8601String(),
        }),
        'schedules': schedules.map((s) => {
          'id': s.id, 'studentId': s.studentId, 'subject': s.subject,
          'dayOfWeek': s.dayOfWeek,
          'startTime': s.startTime.toIso8601String(),
          'endTime': s.endTime.toIso8601String(),
          'repeatRule': s.repeatRule,
          'repeatEndDate': s.repeatEndDate?.toIso8601String(),
          'location': s.location, 'isActive': s.isActive,
          'reminderMinutes': s.reminderMinutes,
          'calendarEventId': s.calendarEventId,
          'scheduleGroupId': s.scheduleGroupId,
          'createdAt': s.createdAt.toIso8601String(),
        }),
        'progressEntries': progress.map((p) => {
          'id': p.id, 'studentId': p.studentId, 'subject': p.subject,
          'topic': p.topic, 'masteryLevel': p.masteryLevel, 'notes': p.notes,
          'createdAt': p.createdAt.toIso8601String(),
          'updatedAt': p.updatedAt.toIso8601String(),
        }),
        'courseFees': fees.map((f) => {
          'id': f.id, 'studentId': f.studentId, 'subject': f.subject,
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
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')],
          subject: '家教日程管家 数据备份');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('备份完成')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('备份失败: $e')));
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('恢复数据'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('⚠️ 此操作将清空当前所有数据并从备份文件导入。\n建议先备份当前数据。'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final data = jsonDecode(await file.readAsString(encoding: utf8))
          as Map<String, dynamic>;
      if (data['version'] == null) throw Exception('无效的备份文件');

      if (!context.mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );

      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        await db.delete(db.courseRecords).go();
        await db.delete(db.schedules).go();
        await db.delete(db.progressEntries).go();
        await db.delete(db.courseFees).go();
        await db.delete(db.students).go();

        for (final s in (data['students'] as List? ?? [])) {
          s as Map<String, dynamic>;
          await db.into(db.students).insert(StudentsCompanion.insert(
            id: s['id'], name: s['name'], grade: s['grade'],
            school: Value(s['school']), phone: Value(s['phone']),
            parentPhone: Value(s['parentPhone']),
            subjects: Value(s['subjects'] ?? '[]'),
            tags: Value(s['tags'] ?? '[]'),
            notes: Value(s['notes']),
            avatarColor: Value(s['avatarColor']),
          ));
        }
        for (final r in (data['courseRecords'] as List? ?? [])) {
          r as Map<String, dynamic>;
          await db.into(db.courseRecords).insert(CourseRecordsCompanion.insert(
            id: r['id'], studentId: r['studentId'], subject: r['subject'],
            date: DateTime.parse(r['date']), duration: r['duration'],
            content: r['content'], homework: Value(r['homework']),
            rating: Value(r['rating'] ?? 3), summary: Value(r['summary']),
            notes: Value(r['notes']),
            fee: Value((r['fee'] as num?)?.toDouble()),
            attachments: Value(r['attachments'] ?? '[]'),
          ));
        }
        for (final s in (data['schedules'] as List? ?? [])) {
          s as Map<String, dynamic>;
          await db.into(db.schedules).insert(SchedulesCompanion.insert(
            id: s['id'], studentId: s['studentId'], subject: s['subject'],
            startTime: DateTime.parse(s['startTime']),
            endTime: DateTime.parse(s['endTime']),
            dayOfWeek: Value(s['dayOfWeek']),
            repeatRule: Value(s['repeatRule'] ?? 'none'),
            repeatEndDate: Value(s['repeatEndDate'] != null
                ? DateTime.parse(s['repeatEndDate']) : null),
            location: Value(s['location']),
            isActive: Value(s['isActive'] ?? true),
            reminderMinutes: Value(s['reminderMinutes'] ?? 30),
            calendarEventId: Value(s['calendarEventId']),
            scheduleGroupId: Value(s['scheduleGroupId']),
          ));
        }
        for (final p in (data['progressEntries'] as List? ?? [])) {
          p as Map<String, dynamic>;
          await db.into(db.progressEntries).insert(
              ProgressEntriesCompanion.insert(
            id: p['id'], studentId: p['studentId'], subject: p['subject'],
            topic: p['topic'],
            masteryLevel: Value(p['masteryLevel'] ?? 3),
            notes: Value(p['notes']),
          ));
        }
        for (final f in (data['courseFees'] as List? ?? [])) {
          f as Map<String, dynamic>;
          await db.into(db.courseFees).insert(CourseFeesCompanion.insert(
            id: f['id'], studentId: f['studentId'], subject: f['subject'],
            feePerHour: (f['feePerHour'] as num).toDouble(),
          ));
        }
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('数据恢复成功')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    }
  }
}

// iOS 分组头部
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: IosColors.secondaryLabel(context))),
    );
  }
}

// iOS 分组容器
class _GroupedContainer extends StatelessWidget {
  final List<Widget> children;
  const _GroupedContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IosColors.secondaryBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// 开关行
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 15)),
        const Spacer(),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// 选择行
class _PickerRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  const _PickerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    color: IosColors.secondaryLabel(context))),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.right_chevron,
                size: 16, color: IosColors.tertiaryLabel(context)),
          ]),
        ),
      ),
      if (!isLast)
        Divider(height: 0.5, indent: 50,
            color: IosColors.separator(context)),
    ]);
  }
}

// 操作行
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: IosColors.secondaryLabel(context))),
                ],
              ),
            ),
            Icon(CupertinoIcons.right_chevron,
                size: 16, color: IosColors.tertiaryLabel(context)),
          ]),
        ),
      ),
      if (!isLast)
        Divider(height: 0.5, indent: 50,
            color: IosColors.separator(context)),
    ]);
  }
}

// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 15, color: IosColors.secondaryLabel(context))),
        ]),
      ),
    ]);
  }
}
