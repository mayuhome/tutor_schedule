import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/color_schemes.dart';
import '../../data/models/course_record_model.dart';

class RecordCard extends StatelessWidget {
  final CourseRecordModel record;
  final VoidCallback? onTap;

  const RecordCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.subjectColor(record.subject);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: IosColors.secondaryBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(record.subject,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
                const SizedBox(width: 8),
                Text(DateFormat('MM月dd日 HH:mm').format(record.date),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.clock,
                    size: 14, color: IosColors.tertiaryLabel(context)),
                const SizedBox(width: 4),
                Text(record.durationText,
                    style: TextStyle(
                        fontSize: 13,
                        color: IosColors.tertiaryLabel(context))),
                if (record.homework != null &&
                    record.homework!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.doc_plaintext,
                      size: 14, color: IosColors.tertiaryLabel(context)),
                  const SizedBox(width: 4),
                  Text('有作业',
                      style: TextStyle(
                          fontSize: 13,
                          color: IosColors.tertiaryLabel(context))),
                ],
              ],
            ),
          ],
        ),
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
