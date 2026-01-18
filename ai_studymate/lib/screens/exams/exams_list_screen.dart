/// Exams List Screen
///
/// Displays all exams grouped by urgency:
/// - Overdue (past dates, not completed)
/// - Urgent (0-3 days)
/// - Upcoming (4+ days)
/// - Completed

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/exam_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_provider.dart';
import '../../widgets/exams/countdown_widget.dart';
import 'create_exam_screen.dart';
import 'exam_detail_screen.dart';

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize exam provider with user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final examProvider = context.read<ExamProvider>();
      if (authProvider.isAuthenticated) {
        examProvider.initialize(authProvider.uid);
      }
    });
  }

  void _navigateToCreateExam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateExamScreen()),
    );
  }

  void _navigateToExamDetail(ExamModel exam) {
    final examProvider = context.read<ExamProvider>();
    examProvider.selectExam(exam);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExamDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        actions: [
          // Refresh button
          Consumer<ExamProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refresh(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateExam,
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, _) {
          // Loading state
          if (examProvider.isLoading && examProvider.exams.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading exams...'),
                ],
              ),
            );
          }

          // Error state
          if (examProvider.errorMessage != null && examProvider.exams.isEmpty) {
            return _buildErrorState(examProvider);
          }

          // Empty state
          if (examProvider.exams.isEmpty) {
            return _buildEmptyState();
          }

          // Exam list
          return RefreshIndicator(
            onRefresh: examProvider.refresh,
            child: _buildExamList(examProvider),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ExamProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load exams',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
                provider.refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'No Exams Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your upcoming exams to track\nthem and stay organized.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateExam,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Exam'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamList(ExamProvider provider) {
    final overdueExams = provider.pastDueExams;
    final urgentExams = provider.urgentExams;
    final upcomingExams = provider.nonUrgentUpcomingExams;
    final completedExams = provider.completedExams;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        _buildStatsRow(provider),
        const SizedBox(height: 16),

        // Overdue section
        if (overdueExams.isNotEmpty) ...[
          _buildSectionHeader(
            'Overdue',
            Icons.warning_amber_rounded,
            AppColors.error,
            overdueExams.length,
          ),
          const SizedBox(height: 8),
          ...overdueExams.map((exam) => _ExamCard(
                exam: exam,
                onTap: () => _navigateToExamDetail(exam),
              )),
          const SizedBox(height: 16),
        ],

        // Urgent section
        if (urgentExams.isNotEmpty) ...[
          _buildSectionHeader(
            'Urgent',
            Icons.priority_high,
            AppColors.warning,
            urgentExams.length,
          ),
          const SizedBox(height: 8),
          ...urgentExams.map((exam) => _ExamCard(
                exam: exam,
                onTap: () => _navigateToExamDetail(exam),
              )),
          const SizedBox(height: 16),
        ],

        // Upcoming section
        if (upcomingExams.isNotEmpty) ...[
          _buildSectionHeader(
            'Upcoming',
            Icons.event,
            AppColors.info,
            upcomingExams.length,
          ),
          const SizedBox(height: 8),
          ...upcomingExams.map((exam) => _ExamCard(
                exam: exam,
                onTap: () => _navigateToExamDetail(exam),
              )),
          const SizedBox(height: 16),
        ],

        // Completed section
        if (completedExams.isNotEmpty) ...[
          _buildSectionHeader(
            'Completed',
            Icons.check_circle,
            AppColors.success,
            completedExams.length,
          ),
          const SizedBox(height: 8),
          ...completedExams.map((exam) => _ExamCard(
                exam: exam,
                onTap: () => _navigateToExamDetail(exam),
              )),
        ],

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatsRow(ExamProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: provider.examCount.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Upcoming',
            value: provider.upcomingCount.toString(),
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: provider.completedCount.toString(),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Stats card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exam card widget
class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Urgency indicator bar
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: exam.urgencyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Exam info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      exam.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        decoration: exam.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Subject
                    Text(
                      exam.subject,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date, time, location chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(Icons.calendar_today, exam.formattedDate),
                        if (exam.examTime != null && exam.examTime!.isNotEmpty)
                          _buildInfoChip(Icons.access_time, exam.formattedTime),
                        if (exam.location != null && exam.location!.isNotEmpty)
                          _buildInfoChip(Icons.location_on, exam.location!),
                        if (exam.hasSyllabus)
                          _buildInfoChip(Icons.list, '${exam.syllabusCount} topics'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Countdown widget
              CountdownWidget(
                daysRemaining: exam.calculatedDaysRemaining,
                isCompleted: exam.isCompleted,
                size: CountdownSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
