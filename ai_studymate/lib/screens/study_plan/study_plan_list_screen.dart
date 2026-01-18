/// Study Plan List Screen
///
/// Displays all study plans for the user.
/// Shows active plan prominently with today's preview,
/// and lists previous plans with view/delete options.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/study_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../widgets/study_plan/daily_schedule_widget.dart';
import 'generate_study_plan_screen.dart';
import 'study_plan_detail_screen.dart';

class StudyPlanListScreen extends StatefulWidget {
  const StudyPlanListScreen({super.key});

  @override
  State<StudyPlanListScreen> createState() => _StudyPlanListScreenState();
}

class _StudyPlanListScreenState extends State<StudyPlanListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    final authProvider = context.read<AuthProvider>();
    final studyPlanProvider = context.read<StudyPlanProvider>();
    if (authProvider.isAuthenticated && authProvider.uid.isNotEmpty) {
      studyPlanProvider.initialize(authProvider.uid);
    }
  }

  Future<void> _refresh() async {
    final studyPlanProvider = context.read<StudyPlanProvider>();
    await studyPlanProvider.refresh();
  }

  void _navigateToGenerate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GenerateStudyPlanScreen()),
    );
  }

  void _navigateToDetail(StudyPlanModel plan) {
    final studyPlanProvider = context.read<StudyPlanProvider>();
    studyPlanProvider.selectPlan(plan);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudyPlanDetailScreen()),
    );
  }

  Future<void> _confirmDelete(StudyPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Plan'),
        content: Text('Are you sure you want to delete "${plan.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final studyPlanProvider = context.read<StudyPlanProvider>();
      final success = await studyPlanProvider.deletePlan(plan.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Study plan deleted' : 'Failed to delete study plan'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyPlanProvider = context.watch<StudyPlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plans'),
        actions: [
          if (studyPlanProvider.hasPlans)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToGenerate,
              tooltip: 'Create New Plan',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(studyPlanProvider),
      ),
      floatingActionButton: studyPlanProvider.hasPlans
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
    );
  }

  Widget _buildBody(StudyPlanProvider provider) {
    if (provider.isLoading && provider.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.plans.isEmpty) {
      return _buildErrorState(provider);
    }

    if (!provider.hasPlans) {
      return _buildEmptyState();
    }

    return _buildPlansList(provider);
  }

  Widget _buildErrorState(StudyPlanProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load study plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Study Plans Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a personalized study schedule based on your subjects and exam dates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Study Plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(StudyPlanProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active plan section
        if (provider.activePlan != null) ...[
          _buildSectionHeader('Current Plan', Icons.play_circle_outline),
          const SizedBox(height: 12),
          _buildActivePlanCard(provider.activePlan!),
          const SizedBox(height: 24),
        ],

        // All plans section
        _buildSectionHeader('All Plans', Icons.list_alt),
        const SizedBox(height: 12),
        ...provider.plansByDate.map((plan) => _buildPlanCard(plan, plan.id == provider.activePlan?.id)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlanCard(StudyPlanModel plan) {
    final todaySchedule = plan.todaysSchedule;

    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    plan.dateRangeFormatted,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: plan.progressPercentage,
                        backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(plan.progressPercentage * 100).round()}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats row
              Row(
                children: [
                  _buildStatChip(Icons.calendar_today, '${plan.totalDays} days'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.schedule, '${plan.totalStudyHours} hours'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.menu_book, '${plan.subjects.length} subjects'),
                ],
              ),

              // Today's preview
              if (todaySchedule != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.today, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...todaySchedule.tasks.take(2).map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TaskPreviewWidget(
                      task: task,
                      color: getSubjectColor(task.subject, plan.subjects),
                    ),
                  );
                }),
                if (todaySchedule.tasks.length > 2)
                  Text(
                    '+${todaySchedule.tasks.length - 2} more tasks',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildPlanCard(StudyPlanModel plan, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.dateRangeFormatted,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(plan);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStatChip(Icons.menu_book, '${plan.subjects.length} subjects'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.calendar_today, '${plan.totalDays} days'),
                  const SizedBox(width: 8),
                  if (plan.isInProgress)
                    _buildStatusChip('In Progress', AppColors.info)
                  else if (plan.hasEnded)
                    _buildStatusChip('Completed', AppColors.success)
                  else
                    _buildStatusChip('Upcoming', AppColors.warning),
                ],
              ),

              // Subject legend
              const SizedBox(height: 12),
              SubjectLegendWidget(subjects: plan.subjects),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
