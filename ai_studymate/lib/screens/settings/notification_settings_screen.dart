/// Notification Settings Screen
///
/// Allows users to manage notification preferences:
/// - Enable/disable exam reminders
/// - Enable/disable daily study reminders
/// - Set daily study reminder time
/// - View pending notification count

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    // Initialize provider if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  Future<void> _loadPendingCount() async {
    final count =
        await context.read<NotificationProvider>().getPendingNotificationCount();
    if (mounted) {
      setState(() => _pendingCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.checkPermissions();
              await _loadPendingCount();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Permission status card
                if (!provider.notificationsPermitted) _buildPermissionCard(provider),

                // Exam reminders section
                _buildSection(
                  title: 'Exam Reminders',
                  icon: Icons.event_note,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Exam Reminders'),
                        subtitle: const Text(
                          'Get notified before your exams based on reminder days (7, 3, 1 day before)',
                        ),
                        value: provider.examRemindersEnabled,
                        onChanged: provider.notificationsPermitted
                            ? (value) => provider.setExamRemindersEnabled(value)
                            : null,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Daily study reminder section
                _buildSection(
                  title: 'Daily Study Reminder',
                  icon: Icons.schedule,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Daily Reminder'),
                        subtitle: const Text(
                          'Get a daily reminder to review your notes and flashcards',
                        ),
                        value: provider.dailyStudyEnabled,
                        onChanged: provider.notificationsPermitted
                            ? (value) => provider.setDailyStudyEnabled(value)
                            : null,
                        activeColor: AppColors.primary,
                      ),
                      if (provider.dailyStudyEnabled) ...[
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                          title: const Text('Reminder Time'),
                          subtitle: Text(provider.formattedDailyStudyTime),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectTime(context, provider),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics section
                _buildSection(
                  title: 'Notification Statistics',
                  icon: Icons.analytics_outlined,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.pending_actions,
                          color: AppColors.info,
                        ),
                        title: const Text('Scheduled Notifications'),
                        subtitle: const Text('Notifications waiting to be sent'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$_pendingCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Information card
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(NotificationProvider provider) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Notifications Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enable notifications to receive exam reminders and daily study alerts. '
              'Without notifications, you may miss important exam dates.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final granted = await provider.requestPermissions();
                  if (mounted && granted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notifications enabled!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    await _loadPendingCount();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please enable notifications in device settings',
                        ),
                        backgroundColor: AppColors.error,
                        action: SnackBarAction(
                          label: 'Open Settings',
                          textColor: Colors.white,
                          onPressed: () {
                            // Open app settings (platform-specific)
                          },
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Enable Notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.info.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'How Notifications Work',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Exam Reminders',
              'Notifications are sent at 7:00 PM on the days you select when creating an exam (default: 7, 3, and 1 day before).',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Daily Study',
              'A daily reminder helps you maintain consistency in your study routine.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Tap to Open',
              'Tapping a notification will take you directly to the relevant exam or screen.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: AppColors.info,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.dailyStudyTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await provider.setDailyStudyTime(picked);
      await _loadPendingCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily reminder set for ${provider.formattedDailyStudyTime}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
