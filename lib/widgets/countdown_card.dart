import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/exam_model.dart';

class CountdownCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CountdownCard(
      {super.key, required this.exam, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = exam.daysRemaining;
    final urgent = days <= 3;
    final label = exam.isToday
        ? 'TODAY'
        : days == 1
            ? '1 day'
            : '$days days';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (urgent ? AppTheme.danger : scheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: exam.isToday ? 13 : 16,
                        color: urgent ? AppTheme.danger : scheme.primary,
                      ),
                    ),
                    if (!exam.isToday)
                      Text('left',
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  urgent ? AppTheme.danger : scheme.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${exam.courseCode} — ${exam.courseName}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('EEE, MMM d').format(exam.examDate)}'
                      '${exam.examTime != null ? ' • ${exam.examTime}' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    if (exam.venue != null)
                      Text(exam.venue!,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
