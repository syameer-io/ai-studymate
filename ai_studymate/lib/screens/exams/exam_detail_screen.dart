/// Exam Detail Screen
///
/// Displays full exam details including:
/// - Large countdown display
/// - Exam information (date, time, location)
/// - Syllabus topics list
/// - Actions (mark complete, edit, delete)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/exams/countdown_widget.dart';
import 'create_exam_screen.dart';

class ExamDetailScreen extends StatelessWidget {
  const ExamDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, _) {
        final exam = examProvider.selectedExam;

        if (exam == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Exam')),
            body: const Center(
              child: Text('Exam not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(exam.displayName),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEdit(context, exam),
                tooltip: 'Edit',
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context, exam, examProvider),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Large countdown card
                _buildCountdownCard(context, exam),
                const SizedBox(height: 16),

                // Details card
                _buildDetailsCard(context, exam),
                const SizedBox(height: 16),

                // Syllabus card
                _buildSyllabusCard(context, exam),
                const SizedBox(height: 16),

                // Actions card
                _buildActionsCard(context, exam, examProvider),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, ExamModel exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExamScreen(editExam: exam),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ExamModel exam,
    ExamProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.displayName}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteExam(exam.id);
      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Exam deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to delete exam'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildCountdownCard(BuildContext context, ExamModel exam) {
    String subtitle;
    if (exam.isCompleted) {
      subtitle = 'Exam Completed';
    } else if (exam.isPastDue) {
      subtitle = 'Exam has passed';
    } else if (exam.isToday) {
      subtitle = 'Exam is TODAY!';
    } else if (exam.isTomorrow) {
      subtitle = 'Exam is TOMORROW!';
    } else {
      subtitle = 'until exam';
    }

    return CountdownCard(
      daysRemaining: exam.calculatedDaysRemaining,
      isCompleted: exam.isCompleted,
      subtitle: subtitle,
    );
  }

  Widget _buildDetailsCard(BuildContext context, ExamModel exam) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Subject
            _buildDetailRow(
              Icons.book_outlined,
              'Subject',
              exam.subject,
            ),
            const Divider(height: 24),

            // Date
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              exam.formattedDateFull,
            ),
            const Divider(height: 24),

            // Time
            _buildDetailRow(
              Icons.access_time,
              'Time',
              exam.formattedTime,
            ),

            // Location (if available)
            if (exam.location != null && exam.location!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                Icons.location_on,
                'Location',
                exam.location!,
              ),
            ],

            // Reminder days
            if (exam.reminderDays.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                Icons.notifications_outlined,
                'Reminders',
                '${exam.reminderDays.map((d) => '$d day${d > 1 ? 's' : ''}').join(', ')} before',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyllabusCard(BuildContext context, ExamModel exam) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Syllabus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (exam.hasSyllabus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${exam.syllabusCount} topics',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (!exam.hasSyllabus)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No syllabus topics',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edit exam to add topics to study',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(exam.syllabus.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exam.syllabus[index],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    ExamModel exam,
    ExamProvider provider,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Toggle completion
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: exam.isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  exam.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: exam.isCompleted ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              title: Text(
                exam.isCompleted ? 'Exam Completed' : 'Mark as Completed',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                exam.isCompleted
                    ? 'Tap to mark as incomplete'
                    : 'Tap when you have completed this exam',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: provider.isSaving
                  ? null
                  : () async {
                      final success = await provider.toggleCompleted(exam.id);
                      if (context.mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Failed to update'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
            ),
            const Divider(),

            // Edit exam
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: AppColors.primary),
              ),
              title: Text(
                'Edit Exam',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Update exam details and syllabus',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _navigateToEdit(context, exam),
            ),
            const Divider(),

            // Delete exam
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: AppColors.error),
              ),
              title: Text(
                'Delete Exam',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
              subtitle: Text(
                'Permanently remove this exam',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _showDeleteConfirmation(context, exam, provider),
            ),
          ],
        ),
      ),
    );
  }
}
