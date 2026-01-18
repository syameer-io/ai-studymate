/// Study Plan Detail Screen
///
/// Displays complete study plan with overview, recommendations,
/// and daily schedules organized by tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/study_plan_model.dart';
import '../../providers/study_plan_provider.dart';
import '../../widgets/study_plan/daily_schedule_widget.dart';

class StudyPlanDetailScreen extends StatefulWidget {
  const StudyPlanDetailScreen({super.key});

  @override
  State<StudyPlanDetailScreen> createState() => _StudyPlanDetailScreenState();
}

class _StudyPlanDetailScreenState extends State<StudyPlanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPlanProvider>();
    final plan = provider.selectedPlan;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Plan')),
        body: const Center(child: Text('No plan selected')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(plan, innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(plan),
            _buildUpcomingTab(plan),
            _buildAllTab(plan),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(StudyPlanModel plan, bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 280,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    plan.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Date range
                  Text(
                    plan.dateRangeFormatted,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: plan.progressPercentage,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(plan.progressPercentage * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _buildStatCard(Icons.calendar_today, '${plan.totalDays}', 'Days'),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.schedule, '${plan.totalStudyHours}', 'Hours'),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.menu_book, '${plan.subjects.length}', 'Subjects'),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.hourglass_empty, '${plan.remainingDays}', 'Left'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        tabs: [
          Tab(
            text: 'Today',
            icon: Icon(
              plan.todaysSchedule != null ? Icons.today : Icons.event_busy,
              size: 20,
            ),
          ),
          const Tab(text: 'Upcoming', icon: Icon(Icons.upcoming, size: 20)),
          const Tab(text: 'All', icon: Icon(Icons.calendar_month, size: 20)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(StudyPlanModel plan) {
    final todaySchedule = plan.todaysSchedule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendations section
          if (plan.recommendations.isNotEmpty) ...[
            _buildRecommendationsCard(plan.recommendations),
            const SizedBox(height: 24),
          ],

          // Today's schedule
          if (todaySchedule != null) ...[
            _buildSectionHeader("Today's Schedule", Icons.today),
            const SizedBox(height: 12),
            DailyScheduleWidget(
              schedule: todaySchedule,
              allSubjects: plan.subjects,
              showDate: false,
            ),
          ] else ...[
            _buildNoScheduleToday(plan),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Card(
      color: AppColors.info.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNoScheduleToday(StudyPlanModel plan) {
    String message;
    IconData icon;
    Color color;

    if (!plan.hasStarted) {
      message = 'Your study plan starts on ${plan.schedule.first.formattedDateWithDay}';
      icon = Icons.event_note;
      color = AppColors.info;
    } else if (plan.hasEnded) {
      message = 'Congratulations! You have completed this study plan.';
      icon = Icons.celebration;
      color = AppColors.success;
    } else {
      message = 'No study session scheduled for today. Enjoy your day off!';
      icon = Icons.beach_access;
      color = AppColors.secondary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(StudyPlanModel plan) {
    final upcomingSchedules = plan.upcomingSchedules;

    if (upcomingSchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: AppColors.success.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'No upcoming schedules',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.hasEnded ? 'This plan has been completed' : 'Check back later',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingSchedules.length,
      itemBuilder: (context, index) {
        return DailyScheduleWidget(
          schedule: upcomingSchedules[index],
          allSubjects: plan.subjects,
        );
      },
    );
  }

  Widget _buildAllTab(StudyPlanModel plan) {
    if (plan.schedule.isEmpty) {
      return const Center(child: Text('No schedule available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Subject legend
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Subjects', Icons.palette),
                const SizedBox(height: 12),
                SubjectLegendWidget(subjects: plan.subjects),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // All schedules
        ...plan.schedule.map((schedule) => DailyScheduleWidget(
          schedule: schedule,
          allSubjects: plan.subjects,
        )),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
