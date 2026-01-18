/// Exam Model
///
/// Represents an exam in the application.
/// Maps to Laravel API responses for exam data.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme_config.dart';

class ExamModel {
  /// Laravel database ID
  final int id;

  /// Owner's Firebase user ID
  final String userId;

  /// Exam name (e.g., "Final Exam", "Midterm")
  final String name;

  /// Subject/course (e.g., "Mathematics", "Physics")
  final String subject;

  /// Exam date
  final DateTime examDate;

  /// Exam time in HH:mm format (optional)
  final String? examTime;

  /// Location/venue (optional)
  final String? location;

  /// List of syllabus topics to study
  final List<String> syllabus;

  /// Days before exam to send reminders (e.g., [7, 3, 1])
  final List<int> reminderDays;

  /// Whether the exam has been completed
  final bool isCompleted;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  const ExamModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.subject,
    required this.examDate,
    this.examTime,
    this.location,
    this.syllabus = const [],
    this.reminderDays = const [7, 3, 1],
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ExamModel from API JSON response
  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] ?? 'Untitled Exam',
      subject: json['subject'] ?? '',
      examDate: _parseDate(json['exam_date']),
      examTime: json['exam_time'],
      location: json['location'],
      syllabus: _parseStringList(json['syllabus']),
      reminderDays: _parseIntList(json['reminder_days']),
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Helper to parse date string (YYYY-MM-DD)
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Helper to parse datetime string
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Helper to parse JSON array to List<String>
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      // Handle if it's a JSON string
      return [];
    }
    return [];
  }

  /// Helper to parse JSON array to List<int>
  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [7, 3, 1];
    if (value is List) {
      return value.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    }
    return [7, 3, 1];
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'userId': userId,
      'name': name,
      'subject': subject,
      'date': DateFormat('yyyy-MM-dd').format(examDate),
      if (examTime != null) 'time': examTime,
      if (location != null && location!.isNotEmpty) 'location': location,
      'syllabus': syllabus,
      'reminderDays': reminderDays,
      'isCompleted': isCompleted,
    };
  }

  /// Create a copy with updated fields
  ExamModel copyWith({
    int? id,
    String? userId,
    String? name,
    String? subject,
    DateTime? examDate,
    String? examTime,
    String? location,
    List<String>? syllabus,
    List<int>? reminderDays,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      examTime: examTime ?? this.examTime,
      location: location ?? this.location,
      syllabus: syllabus ?? this.syllabus,
      reminderDays: reminderDays ?? this.reminderDays,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Calculate days remaining until exam
  int get calculatedDaysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(examDate.year, examDate.month, examDate.day);
    return examDay.difference(today).inDays;
  }

  /// Check if exam date has passed
  bool get isPastDue => calculatedDaysRemaining < 0;

  /// Check if exam is today
  bool get isToday => calculatedDaysRemaining == 0;

  /// Check if exam is tomorrow
  bool get isTomorrow => calculatedDaysRemaining == 1;

  /// Check if exam is urgent (within 3 days and not completed)
  bool get isUrgent => calculatedDaysRemaining <= 3 && calculatedDaysRemaining >= 0 && !isCompleted;

  /// Check if exam is upcoming (within 7 days)
  bool get isUpcoming => calculatedDaysRemaining <= 7 && calculatedDaysRemaining > 0 && !isCompleted;

  /// Get urgency color based on days remaining
  Color get urgencyColor {
    if (isCompleted) return AppColors.success;
    if (isPastDue) return AppColors.error;
    if (calculatedDaysRemaining <= 1) return AppColors.error; // Red
    if (calculatedDaysRemaining <= 3) return AppColors.warning; // Yellow/Orange
    if (calculatedDaysRemaining <= 7) return AppColors.info; // Blue
    return AppColors.success; // Green
  }

  /// Get formatted date string (e.g., "Dec 25, 2024")
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(examDate);
  }

  /// Get formatted date with day name (e.g., "Monday, Dec 25, 2024")
  String get formattedDateFull {
    return DateFormat('EEEE, MMM d, yyyy').format(examDate);
  }

  /// Get formatted time string (e.g., "9:00 AM")
  String get formattedTime {
    if (examTime == null || examTime!.isEmpty) return 'No time set';
    try {
      final parts = examTime!.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final time = TimeOfDay(hour: hour, minute: minute);
        final now = DateTime.now();
        final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        return DateFormat('h:mm a').format(dateTime);
      }
    } catch (_) {}
    return examTime!;
  }

  /// Get combined date and time string
  String get formattedDateTime {
    if (examTime == null || examTime!.isEmpty) {
      return formattedDate;
    }
    return '$formattedDate at $formattedTime';
  }

  /// Get countdown display text
  String get countdownDisplay {
    if (isCompleted) return 'Completed';
    if (isPastDue) {
      final days = calculatedDaysRemaining.abs();
      return days == 1 ? '1 day ago' : '$days days ago';
    }
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    final days = calculatedDaysRemaining;
    return days == 1 ? '1 day' : '$days days';
  }

  /// Get countdown label (for below the number)
  String get countdownLabel {
    if (isCompleted) return '';
    if (isPastDue) return 'overdue';
    if (isToday) return '';
    if (isTomorrow) return '';
    return calculatedDaysRemaining == 1 ? 'day left' : 'days left';
  }

  /// Check if exam has syllabus topics
  bool get hasSyllabus => syllabus.isNotEmpty;

  /// Get syllabus count
  int get syllabusCount => syllabus.length;

  /// Get display name (fallback to 'Untitled Exam')
  String get displayName {
    if (name.isNotEmpty) return name;
    return 'Untitled Exam';
  }

  @override
  String toString() {
    return 'ExamModel(id: $id, name: $name, subject: $subject, examDate: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
