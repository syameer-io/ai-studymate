/// Daily Schedule Widget
///
/// Displays a single day's study schedule with tasks.
/// Used in study plan detail and list screens.

import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/study_plan_model.dart';

/// Color map for subjects (rotates through colors)
final List<Color> _subjectColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.accent,
  AppColors.info,
  AppColors.success,
  const Color(0xFF9B59B6), // Purple
  const Color(0xFFE67E22), // Orange
  const Color(0xFF1ABC9C), // Turquoise
];

/// Get color for a subject (consistent color per subject name)
Color getSubjectColor(String subject, Set<String> allSubjects) {
  final index = allSubjects.toList().indexOf(subject);
  return _subjectColors[index % _subjectColors.length];
}

/// Daily Schedule Widget
class DailyScheduleWidget extends StatelessWidget {
  final DailySchedule schedule;
  final Set<String> allSubjects;
  final bool showDate;
  final bool isCompact;

  const DailyScheduleWidget({
    super.key,
    required this.schedule,
    required this.allSubjects,
    this.showDate = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            if (showDate) ...[
              _buildDateHeader(context),
              SizedBox(height: isCompact ? 8 : 12),
            ],

            // Task list
            ...schedule.tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < schedule.tasks.length - 1 ? (isCompact ? 8 : 12) : 0,
                ),
                child: _buildTaskItem(context, task),
              );
            }),

            // Total hours footer
            if (!isCompact && schedule.tasks.length > 1) ...[
              const Divider(height: 24),
              _buildTotalHours(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: schedule.isToday
                ? AppColors.primary
                : (schedule.isPast ? AppColors.textLight : AppColors.secondary),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                schedule.isToday ? Icons.today : Icons.calendar_today,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                schedule.isToday ? 'Today' : schedule.formattedDateWithDay,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${schedule.totalHours} ${schedule.totalHours == 1 ? 'hour' : 'hours'}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, StudyTask task) {
    final color = getSubjectColor(task.subject, allSubjects);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        SizedBox(
          width: isCompact ? 50 : 60,
          child: Text(
            task.formattedTime,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Color indicator
        Container(
          width: 4,
          height: isCompact ? 40 : 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),

        // Task details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.subject,
                  style: TextStyle(
                    color: color,
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Topic
              Text(
                task.topic,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isCompact ? 13 : 14,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Duration
              if (!isCompact) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.formattedDuration,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalHours(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Total: ${schedule.totalHours} ${schedule.totalHours == 1 ? 'hour' : 'hours'}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Compact task preview for list screens
class TaskPreviewWidget extends StatelessWidget {
  final StudyTask task;
  final Color color;

  const TaskPreviewWidget({
    super.key,
    required this.task,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.subject,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                task.topic,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          task.formattedDuration,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

/// Subject legend widget
class SubjectLegendWidget extends StatelessWidget {
  final Set<String> subjects;

  const SubjectLegendWidget({
    super.key,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: subjects.map((subject) {
        final color = getSubjectColor(subject, subjects);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              subject,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
