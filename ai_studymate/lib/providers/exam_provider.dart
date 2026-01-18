/// Exam Provider
///
/// State management for exams using ChangeNotifier pattern.
/// Handles loading, creating, updating, and deleting exams.

import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ExamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  // ========== STATE ==========

  /// All exams for the current user
  List<ExamModel> _exams = [];
  List<ExamModel> get exams => _exams;

  /// Upcoming exams (not completed, future dates)
  List<ExamModel> _upcomingExams = [];
  List<ExamModel> get upcomingExams => _upcomingExams;

  /// Currently selected exam for detail view
  ExamModel? _selectedExam;
  ExamModel? get selectedExam => _selectedExam;

  // ========== LOADING STATES ==========

  /// Loading state for fetching exams
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Saving state for create/update operations
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // ========== ERROR STATE ==========

  /// Error message from last operation
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========== USER STATE ==========

  /// Current user's Firebase UID
  String? _userId;
  String? get userId => _userId;

  // ========== COMPUTED PROPERTIES ==========

  /// Check if there are any exams
  bool get hasExams => _exams.isNotEmpty;

  /// Get total exam count
  int get examCount => _exams.length;

  /// Get upcoming exam count
  int get upcomingCount => _upcomingExams.length;

  /// Get completed exam count
  int get completedCount => _exams.where((e) => e.isCompleted).length;

  /// Get urgent exams (within 3 days, not completed)
  List<ExamModel> get urgentExams =>
      _exams.where((e) => e.isUrgent && !e.isCompleted).toList()
        ..sort((a, b) => a.examDate.compareTo(b.examDate));

  /// Get non-urgent upcoming exams (4-7 days away, not completed)
  List<ExamModel> get nonUrgentUpcomingExams =>
      _exams.where((e) => !e.isUrgent && e.calculatedDaysRemaining > 0 && !e.isCompleted).toList()
        ..sort((a, b) => a.examDate.compareTo(b.examDate));

  /// Get completed exams
  List<ExamModel> get completedExams =>
      _exams.where((e) => e.isCompleted).toList()
        ..sort((a, b) => b.examDate.compareTo(a.examDate));

  /// Get past due exams (not completed, date has passed)
  List<ExamModel> get pastDueExams =>
      _exams.where((e) => e.isPastDue && !e.isCompleted).toList()
        ..sort((a, b) => b.examDate.compareTo(a.examDate));

  /// Get all exams sorted by date (ascending)
  List<ExamModel> get examsByDate {
    final sorted = List<ExamModel>.from(_exams);
    sorted.sort((a, b) => a.examDate.compareTo(b.examDate));
    return sorted;
  }

  /// Get next upcoming exam
  ExamModel? get nextExam {
    final upcoming = _exams
        .where((e) => !e.isCompleted && !e.isPastDue)
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  // ========== INITIALIZATION ==========

  /// Initialize provider with user ID and load exams
  void initialize(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _exams = [];
      _upcomingExams = [];
      _selectedExam = null;
      loadExams();
    }
  }

  /// Clear all state
  void clear() {
    _userId = null;
    _exams = [];
    _upcomingExams = [];
    _selectedExam = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  // ========== LOAD EXAMS ==========

  /// Load all exams from API
  Future<void> loadExams() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      _exams = await _apiService.getExams(_userId!);

      // Also update upcoming exams
      _upcomingExams = _exams
          .where((e) => !e.isCompleted && !e.isPastDue)
          .toList()
        ..sort((a, b) => a.examDate.compareTo(b.examDate));
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load exams: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Load upcoming exams from API
  Future<void> loadUpcomingExams() async {
    if (_userId == null) return;

    try {
      _upcomingExams = await _apiService.getUpcomingExams(_userId!);
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load upcoming exams: $e';
      notifyListeners();
    }
  }

  /// Refresh all exam data
  Future<void> refresh() async {
    await loadExams();
  }

  // ========== CRUD OPERATIONS ==========

  /// Create a new exam
  Future<bool> createExam({
    required String name,
    required String subject,
    required DateTime examDate,
    String? examTime,
    String? location,
    List<String> syllabus = const [],
    List<int> reminderDays = const [7, 3, 1],
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _setSaving(true);
      _errorMessage = null;

      final exam = ExamModel(
        id: 0, // Will be set by API
        userId: _userId!,
        name: name,
        subject: subject,
        examDate: examDate,
        examTime: examTime,
        location: location,
        syllabus: syllabus,
        reminderDays: reminderDays,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedExam = await _apiService.createExam(exam);

      // Add to local list
      _exams.insert(0, savedExam);

      // Update upcoming list if applicable
      if (!savedExam.isCompleted && !savedExam.isPastDue) {
        _upcomingExams.add(savedExam);
        _upcomingExams.sort((a, b) => a.examDate.compareTo(b.examDate));
      }

      // Schedule notification reminders for this exam
      await _notificationService.scheduleExamReminders(savedExam);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create exam: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Update an existing exam
  Future<bool> updateExam(ExamModel exam) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _setSaving(true);
      _errorMessage = null;

      final updatedExam = await _apiService.updateExam(exam.copyWith(
        userId: _userId,
      ));

      // Update in local list
      final index = _exams.indexWhere((e) => e.id == exam.id);
      if (index != -1) {
        _exams[index] = updatedExam;
      }

      // Update selected exam if it's the same
      if (_selectedExam?.id == exam.id) {
        _selectedExam = updatedExam;
      }

      // Update upcoming list
      _upcomingExams = _exams
          .where((e) => !e.isCompleted && !e.isPastDue)
          .toList()
        ..sort((a, b) => a.examDate.compareTo(b.examDate));

      // Reschedule notification reminders for updated exam
      await _notificationService.rescheduleExamReminders(updatedExam);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update exam: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Delete an exam
  Future<bool> deleteExam(int examId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _setSaving(true);
      _errorMessage = null;

      await _apiService.deleteExam(examId, _userId!);

      // Cancel notification reminders for deleted exam
      await _notificationService.cancelExamReminders(examId);

      // Remove from local lists
      _exams.removeWhere((e) => e.id == examId);
      _upcomingExams.removeWhere((e) => e.id == examId);

      // Clear selected if it was deleted
      if (_selectedExam?.id == examId) {
        _selectedExam = null;
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete exam: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Toggle exam completion status
  Future<bool> toggleCompleted(int examId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    // Find the exam
    final examIndex = _exams.indexWhere((e) => e.id == examId);
    if (examIndex == -1) {
      _errorMessage = 'Exam not found';
      notifyListeners();
      return false;
    }

    final exam = _exams[examIndex];
    final newCompletedStatus = !exam.isCompleted;

    try {
      _setSaving(true);
      _errorMessage = null;

      final updatedExam = await _apiService.toggleExamCompleted(
        examId,
        newCompletedStatus,
        _userId!,
      );

      // Update in local list
      _exams[examIndex] = updatedExam;

      // Update selected exam if it's the same
      if (_selectedExam?.id == examId) {
        _selectedExam = updatedExam;
      }

      // Update upcoming list
      _upcomingExams = _exams
          .where((e) => !e.isCompleted && !e.isPastDue)
          .toList()
        ..sort((a, b) => a.examDate.compareTo(b.examDate));

      // Handle notification reminders based on completion status
      if (updatedExam.isCompleted) {
        // Cancel reminders if exam is marked complete
        await _notificationService.cancelExamReminders(examId);
      } else {
        // Reschedule reminders if exam is marked incomplete
        await _notificationService.scheduleExamReminders(updatedExam);
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update exam: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ========== SELECTION ==========

  /// Select an exam for detail view
  void selectExam(ExamModel exam) {
    _selectedExam = exam;
    notifyListeners();
  }

  /// Clear selected exam
  void clearSelectedExam() {
    _selectedExam = null;
    notifyListeners();
  }

  /// Get exam by ID
  ExamModel? getExamById(int examId) {
    try {
      return _exams.firstWhere((e) => e.id == examId);
    } catch (_) {
      return null;
    }
  }

  // ========== NOTIFICATIONS ==========

  /// Reschedule all notifications for upcoming exams
  ///
  /// Call this on app startup to ensure notifications are scheduled
  /// for all existing exams (e.g., after device restart).
  Future<void> rescheduleAllNotifications() async {
    for (final exam in _exams) {
      if (!exam.isCompleted && !exam.isPastDue) {
        await _notificationService.scheduleExamReminders(exam);
      }
    }
    debugPrint('Rescheduled notifications for ${_exams.where((e) => !e.isCompleted && !e.isPastDue).length} exams');
  }
}
