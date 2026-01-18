/// Notification Provider
///
/// Manages notification preferences and scheduled notifications.
/// Uses SharedPreferences to persist user preferences.
///
/// Features:
/// - Toggle exam reminders on/off
/// - Toggle daily study reminders on/off
/// - Set daily study reminder time
/// - Track system permission status
///
/// Usage:
///   final provider = context.read<NotificationProvider>();
///   await provider.initialize();
///   provider.setDailyStudyEnabled(true);

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // ========== STATE ==========

  /// Whether exam reminders are enabled
  bool _examRemindersEnabled = true;
  bool get examRemindersEnabled => _examRemindersEnabled;

  /// Whether daily study reminders are enabled
  bool _dailyStudyEnabled = false;
  bool get dailyStudyEnabled => _dailyStudyEnabled;

  /// Time for daily study reminder (default 7:00 PM)
  TimeOfDay _dailyStudyTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay get dailyStudyTime => _dailyStudyTime;

  /// Whether notifications are permitted by the system
  bool _notificationsPermitted = false;
  bool get notificationsPermitted => _notificationsPermitted;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ========== PREFERENCE KEYS ==========

  static const String _examRemindersKey = 'exam_reminders_enabled';
  static const String _dailyStudyKey = 'daily_study_enabled';
  static const String _dailyStudyHourKey = 'daily_study_hour';
  static const String _dailyStudyMinuteKey = 'daily_study_minute';

  // ========== INITIALIZATION ==========

  /// Initialize provider and load preferences
  ///
  /// Should be called when the app starts or when user logs in.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Check system permission status
      _notificationsPermitted =
          await _notificationService.areNotificationsEnabled();

      // Load saved preferences
      await _loadPreferences();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notification provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _examRemindersEnabled = prefs.getBool(_examRemindersKey) ?? true;
    _dailyStudyEnabled = prefs.getBool(_dailyStudyKey) ?? false;

    final dailyHour = prefs.getInt(_dailyStudyHourKey) ?? 19;
    final dailyMinute = prefs.getInt(_dailyStudyMinuteKey) ?? 0;
    _dailyStudyTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);

    // If daily study is enabled, ensure it's scheduled
    if (_dailyStudyEnabled && _notificationsPermitted) {
      await _notificationService.scheduleDailyStudyReminder(_dailyStudyTime);
    }
  }

  /// Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_examRemindersKey, _examRemindersEnabled);
    await prefs.setBool(_dailyStudyKey, _dailyStudyEnabled);
    await prefs.setInt(_dailyStudyHourKey, _dailyStudyTime.hour);
    await prefs.setInt(_dailyStudyMinuteKey, _dailyStudyTime.minute);
  }

  // ========== PERMISSION MANAGEMENT ==========

  /// Request notification permissions
  ///
  /// Returns true if permission granted, false otherwise.
  Future<bool> requestPermissions() async {
    _notificationsPermitted = await _notificationService.requestPermissions();
    notifyListeners();
    return _notificationsPermitted;
  }

  /// Check if notifications are enabled
  ///
  /// Updates the permission status and notifies listeners.
  Future<void> checkPermissions() async {
    _notificationsPermitted =
        await _notificationService.areNotificationsEnabled();
    notifyListeners();
  }

  // ========== EXAM REMINDERS ==========

  /// Toggle exam reminders on/off
  ///
  /// Note: This just controls the preference. Individual exam reminders
  /// are managed by ExamProvider.
  Future<void> setExamRemindersEnabled(bool enabled) async {
    if (_examRemindersEnabled == enabled) return;

    _examRemindersEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  // ========== DAILY STUDY REMINDERS ==========

  /// Toggle daily study reminders on/off
  ///
  /// When enabled, schedules a daily notification at the set time.
  /// When disabled, cancels the daily notification.
  Future<void> setDailyStudyEnabled(bool enabled) async {
    if (_dailyStudyEnabled == enabled) return;

    _dailyStudyEnabled = enabled;
    await _savePreferences();

    if (enabled && _notificationsPermitted) {
      await _notificationService.scheduleDailyStudyReminder(_dailyStudyTime);
    } else {
      await _notificationService.cancelDailyStudyReminder();
    }

    notifyListeners();
  }

  /// Update daily study reminder time
  ///
  /// [time] - The new time for the daily reminder.
  /// Reschedules the notification if daily study is enabled.
  Future<void> setDailyStudyTime(TimeOfDay time) async {
    if (_dailyStudyTime == time) return;

    _dailyStudyTime = time;
    await _savePreferences();

    if (_dailyStudyEnabled && _notificationsPermitted) {
      await _notificationService.scheduleDailyStudyReminder(_dailyStudyTime);
    }

    notifyListeners();
  }

  // ========== UTILITY ==========

  /// Get count of pending notifications
  ///
  /// Returns the number of scheduled notifications that haven't been shown yet.
  Future<int> getPendingNotificationCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }

  /// Cancel all notifications
  ///
  /// Cancels all scheduled notifications. Use with caution.
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    notifyListeners();
  }

  /// Get formatted daily study time string
  ///
  /// Returns time in "7:00 PM" format for display.
  String get formattedDailyStudyTime {
    final hour = _dailyStudyTime.hourOfPeriod;
    final minute = _dailyStudyTime.minute.toString().padLeft(2, '0');
    final period = _dailyStudyTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }
}
