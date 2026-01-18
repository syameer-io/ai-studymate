/// Notification Service
///
/// Handles local notifications and Firebase Cloud Messaging.
/// Provides methods to schedule, cancel, and manage notifications.
///
/// Features:
/// - Local scheduled notifications for exam reminders
/// - Daily study reminders
/// - Firebase Cloud Messaging for push notifications
/// - Deep linking from notification taps
///
/// Usage:
///   final notificationService = NotificationService();
///   await notificationService.initialize();
///   await notificationService.scheduleExamReminders(exam);

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/exam_model.dart';

/// Custom exception for notification errors
class NotificationException implements Exception {
  final String message;
  final String? code;

  const NotificationException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Notification service singleton
class NotificationService {
  // ========== SINGLETON PATTERN ==========

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ========== INSTANCES ==========

  /// Flutter local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Firebase Cloud Messaging instance
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ========== NOTIFICATION CHANNELS ==========

  /// Exam reminders channel
  static const String examReminderChannelId = 'exam_reminders';
  static const String examReminderChannelName = 'Exam Reminders';
  static const String examReminderChannelDesc =
      'Notifications for upcoming exams';

  /// Daily study reminders channel
  static const String dailyStudyChannelId = 'daily_study';
  static const String dailyStudyChannelName = 'Daily Study Reminders';
  static const String dailyStudyChannelDesc = 'Daily reminders to study';

  /// Push notifications channel
  static const String pushNotificationChannelId = 'push_notifications';
  static const String pushNotificationChannelName = 'Push Notifications';
  static const String pushNotificationChannelDesc = 'Remote push notifications';

  // ========== NOTIFICATION IDS ==========

  /// Fixed ID for daily study reminder
  static const int dailyStudyNotificationId = 99999;

  /// Default reminder time (7:00 PM)
  static const int defaultReminderHour = 19;
  static const int defaultReminderMinute = 0;

  // ========== STATE ==========

  /// Initialization flag
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Callback for notification tap - set this from main.dart
  static Function(String? payload)? onNotificationTap;

  // ========== INITIALIZATION ==========

  /// Initialize the notification service
  ///
  /// Must be called before using any notification methods.
  /// Typically called in main() before runApp().
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Cloud Messaging
      await _initializeFCM();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
      throw NotificationException('Failed to initialize notifications: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin with callback for notification taps
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Exam reminders channel - high importance
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          examReminderChannelId,
          examReminderChannelName,
          description: examReminderChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Daily study reminders channel - default importance
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          dailyStudyChannelId,
          dailyStudyChannelName,
          description: dailyStudyChannelDesc,
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );

      // Push notifications channel - high importance
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          pushNotificationChannelId,
          pushNotificationChannelName,
          description: pushNotificationChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Request permission (especially for iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get FCM token for this device
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: Send new token to backend if needed for targeted push
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // ========== PERMISSION MANAGEMENT ==========

  /// Request notification permissions (Android 13+)
  ///
  /// Returns true if permission granted, false otherwise.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    }
    return true;
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        try {
          return await androidPlugin.canScheduleExactNotifications() ?? false;
        } catch (e) {
          debugPrint('Error checking exact alarm permission: $e');
          return false;
        }
      }
    }
    return true;
  }

  /// Request exact alarm permission (Android 12+)
  ///
  /// On Android 12+, this will open system settings where user can grant permission.
  /// Returns true if permission is already granted or granted after request.
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        try {
          // Check if already permitted
          final canSchedule = await androidPlugin.canScheduleExactNotifications();
          if (canSchedule == true) {
            return true;
          }

          // Request permission (opens system settings)
          final granted = await androidPlugin.requestExactAlarmsPermission();
          return granted ?? false;
        } catch (e) {
          debugPrint('Error requesting exact alarm permission: $e');
          return false;
        }
      }
    }
    return true;
  }

  // ========== EXAM REMINDER METHODS ==========

  /// Schedule all reminders for an exam based on reminderDays
  ///
  /// [exam] - The exam to schedule reminders for
  ///
  /// Schedules notifications for each day in exam.reminderDays
  /// (e.g., [7, 3, 1] means 7 days, 3 days, and 1 day before)
  ///
  /// Returns true if successful, false if exact alarm permission is denied.
  /// Does not throw exceptions - errors are logged but not propagated.
  Future<bool> scheduleExamReminders(ExamModel exam) async {
    try {
      if (!_isInitialized) await initialize();

      // Check if exact alarms are permitted
      if (Platform.isAndroid) {
        final canSchedule = await canScheduleExactAlarms();
        if (!canSchedule) {
          debugPrint('Cannot schedule exact alarms - permission not granted');
          return false;
        }
      }

      // Cancel any existing reminders for this exam first
      await cancelExamReminders(exam.id);

      // Don't schedule reminders for completed or past exams
      if (exam.isCompleted || exam.isPastDue) {
        debugPrint('Skipping reminders for exam ${exam.id}: completed or past due');
        return true; // Not an error
      }

      // Schedule a reminder for each reminder day
      int successCount = 0;
      for (final daysBeforeExam in exam.reminderDays) {
        try {
          await _scheduleExamReminder(exam, daysBeforeExam);
          successCount++;
        } catch (e) {
          debugPrint('Failed to schedule reminder for exam ${exam.id}, day $daysBeforeExam: $e');
        }
      }

      debugPrint('Scheduled $successCount/${exam.reminderDays.length} reminders for exam ${exam.id}');
      return successCount > 0;
    } catch (e) {
      debugPrint('Error scheduling exam reminders: $e');
      return false;
    }
  }

  /// Schedule a single exam reminder
  Future<void> _scheduleExamReminder(ExamModel exam, int daysBefore) async {
    // Calculate the notification date (at 7:00 PM)
    final reminderDate = exam.examDate.subtract(Duration(days: daysBefore));
    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      defaultReminderHour,
      defaultReminderMinute,
    );

    // Don't schedule if the reminder date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint(
          'Skipping past reminder: ${exam.id} - $daysBefore days before');
      return;
    }

    // Create unique notification ID: examId * 100 + daysBefore
    // This allows up to 99 different reminder days per exam
    final notificationId = exam.id * 100 + daysBefore;

    // Build notification title and body
    final title = _buildReminderTitle(exam, daysBefore);
    final body = _buildReminderBody(exam, daysBefore);

    // Create payload for deep linking
    final payload = jsonEncode({
      'type': 'exam_reminder',
      'examId': exam.id,
      'examName': exam.name,
    });

    // Schedule the notification
    await _localNotifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          examReminderChannelId,
          examReminderChannelName,
          channelDescription: examReminderChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint(
        'Scheduled reminder for exam ${exam.id}: $daysBefore days before at $scheduledDate');
  }

  /// Build reminder title based on days before exam
  String _buildReminderTitle(ExamModel exam, int daysBefore) {
    if (daysBefore == 0) {
      return 'Exam TODAY: ${exam.name}';
    } else if (daysBefore == 1) {
      return 'Exam TOMORROW: ${exam.name}';
    } else {
      return 'Exam in $daysBefore days: ${exam.name}';
    }
  }

  /// Build reminder body with exam details
  String _buildReminderBody(ExamModel exam, int daysBefore) {
    final buffer = StringBuffer();
    buffer.write(exam.subject);

    if (exam.examTime != null && exam.examTime!.isNotEmpty) {
      buffer.write(' at ${exam.formattedTime}');
    }

    if (exam.location != null && exam.location!.isNotEmpty) {
      buffer.write(' - ${exam.location}');
    }

    if (daysBefore <= 3 && exam.hasSyllabus) {
      buffer.write('\n${exam.syllabusCount} topics to review');
    }

    return buffer.toString();
  }

  /// Cancel all reminders for a specific exam
  ///
  /// [examId] - The exam ID to cancel reminders for
  Future<void> cancelExamReminders(int examId) async {
    if (!_isInitialized) return;

    // Cancel all possible reminder notifications for this exam
    // We use examId * 100 + daysBefore as the notification ID
    // Common reminder days: 14, 7, 3, 1, 0
    final possibleDays = [14, 7, 3, 1, 0];

    for (final day in possibleDays) {
      final notificationId = examId * 100 + day;
      await _localNotifications.cancel(notificationId);
    }

    debugPrint('Cancelled all reminders for exam $examId');
  }

  /// Reschedule reminders for an updated exam
  ///
  /// Cancels existing reminders and schedules new ones.
  /// Returns true if successful, false if permission is denied.
  Future<bool> rescheduleExamReminders(ExamModel exam) async {
    try {
      await cancelExamReminders(exam.id);
      return await scheduleExamReminders(exam);
    } catch (e) {
      debugPrint('Error rescheduling exam reminders: $e');
      return false;
    }
  }

  // ========== DAILY STUDY REMINDER ==========

  /// Schedule daily study reminder at a specific time
  ///
  /// [time] - The time of day to show the reminder
  ///
  /// This creates a repeating daily notification.
  Future<void> scheduleDailyStudyReminder(TimeOfDay time) async {
    if (!_isInitialized) await initialize();

    // Cancel existing daily reminder
    await _localNotifications.cancel(dailyStudyNotificationId);

    // Calculate next occurrence
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      dailyStudyNotificationId,
      'Time to Study!',
      'Consistency is key. Take some time to review your notes and flashcards.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          dailyStudyChannelId,
          dailyStudyChannelName,
          channelDescription: dailyStudyChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'daily_study'}),
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint(
        'Scheduled daily study reminder at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Cancel daily study reminder
  Future<void> cancelDailyStudyReminder() async {
    await _localNotifications.cancel(dailyStudyNotificationId);
    debugPrint('Cancelled daily study reminder');
  }

  // ========== NOTIFICATION HANDLERS ==========

  /// Handle notification tap response (foreground)
  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped with payload: $payload');

    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  /// Handle background notification response
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('Background notification response: ${response.payload}');
    // Background handling - payload will be processed when app opens
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground FCM message: ${message.notification?.title}');

    // Show local notification for foreground FCM messages
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'AI StudyMate',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle FCM message tap (when app is opened from notification)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM message opened app: ${message.data}');

    if (onNotificationTap != null) {
      onNotificationTap!(jsonEncode(message.data));
    }
  }

  // ========== UTILITY METHODS ==========

  /// Show an immediate notification
  ///
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [payload] - Optional JSON payload for deep linking
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          pushNotificationChannelId,
          pushNotificationChannelName,
          channelDescription: pushNotificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Get all pending notifications
  ///
  /// Returns a list of scheduled but not yet shown notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Cancel all notifications
  ///
  /// Use with caution - cancels ALL scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Get FCM token for this device
  ///
  /// Can be sent to backend for targeted push notifications.
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}

/// Top-level function for handling background FCM messages
///
/// This must be a top-level function (not a class method) for FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message received: ${message.messageId}');
  // Handle background message if needed
  // Note: Heavy processing should be avoided here
}
