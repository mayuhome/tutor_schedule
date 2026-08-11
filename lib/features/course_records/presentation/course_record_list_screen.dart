import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/color_schemes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/course_record_providers.dart';
import '../data/models/course_record_model.dart';

class CourseRecordListScreen extends ConsumerWidget {
  final String? studentId;
  const CourseRecordListScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = studentId != null
        ? ref.watch(recordsByStudentProvider(studentId!))
        : ref.watch(courseRecordListProvider);

    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: const Text('课程记录'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const EmptyState(
              icon: CupertinoIcons.doc_plaintext,
              title: '暂无课程记录',
              subtitle: '完成课程后记录教学内容',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) =>
                _RecordCard(record: records[index]),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final CourseRecordModel record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.subjectColor(record.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IosColors.secondaryBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(record.subject,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ),
              const SizedBox(width: 8),
              Text(DateFormat('MM月dd日').format(record.date),
                  style: TextStyle(
                      fontSize: 13,
                      color: IosColors.secondaryLabel(context))),
              const Spacer(),
              if (record.fee != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('¥${record.fee!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: IosColors.systemBlue)),
                ),
              _RatingStars(rating: record.rating),
            ],
          ),
          const SizedBox(height: 10),
          Text(record.content,
              style: const TextStyle(fontSize: 15),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.doc_text,
                    size: 14, color: IosColors.tertiaryLabel(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(record.notes!,
                      style: TextStyle(
                          fontSize: 13,
                          color: IosColors.secondaryLabel(context)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(CupertinoIcons.clock,
                size: 14, color: IosColors.tertiaryLabel(context)),
            const SizedBox(width: 4),
            Text(record.durationText,
                style: TextStyle(
                    fontSize: 13, color: IosColors.tertiaryLabel(context))),
            if (record.homework != null && record.homework!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Icon(CupertinoIcons.doc_plaintext,
                  size: 14, color: IosColors.tertiaryLabel(context)),
              const SizedBox(width: 4),
              Text('有作业',
                  style: TextStyle(
                      fontSize: 13, color: IosColors.tertiaryLabel(context))),
            ],
          ]),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int rating;
  const _RatingStars({required this.rating});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
        size: 14,
        color: i < rating
            ? AppColors.ratingColor(rating)
            : IosColors.tertiaryLabel(context),
      )),
    );
  }
}
