/// Study Plan Provider
///
/// State management for study plans using ChangeNotifier pattern.
/// Handles loading, generating, and deleting study plans.

import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../services/api_service.dart';

class StudyPlanProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ========== STATE ==========

  /// All study plans for the current user
  List<StudyPlanModel> _plans = [];
  List<StudyPlanModel> get plans => _plans;

  /// Currently active study plan
  StudyPlanModel? _activePlan;
  StudyPlanModel? get activePlan => _activePlan;

  /// Currently selected plan for detail view
  StudyPlanModel? _selectedPlan;
  StudyPlanModel? get selectedPlan => _selectedPlan;

  // ========== LOADING STATES ==========

  /// Loading state for fetching plans
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Generating state for creating new plans
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // ========== ERROR STATE ==========

  /// Error message from last operation
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========== USER STATE ==========

  /// Current user's Firebase UID
  String? _userId;
  String? get userId => _userId;

  // ========== COMPUTED PROPERTIES ==========

  /// Check if there are any plans
  bool get hasPlans => _plans.isNotEmpty;

  /// Get total plan count
  int get planCount => _plans.length;

  /// Get plans sorted by creation date (newest first)
  List<StudyPlanModel> get plansByDate {
    final sorted = List<StudyPlanModel>.from(_plans);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Get in-progress plans
  List<StudyPlanModel> get inProgressPlans =>
      _plans.where((p) => p.isInProgress).toList();

  /// Get completed plans (ended)
  List<StudyPlanModel> get completedPlans =>
      _plans.where((p) => p.hasEnded).toList();

  /// Get upcoming plans (not started yet)
  List<StudyPlanModel> get upcomingPlans =>
      _plans.where((p) => !p.hasStarted).toList();

  // ========== INITIALIZATION ==========

  /// Initialize provider with user ID and load plans
  void initialize(String userId) {
    if (userId.isEmpty) return; // Don't initialize with empty userId
    if (_userId != userId) {
      _userId = userId;
      _plans = [];
      _activePlan = null;
      _selectedPlan = null;
      loadPlans();
    }
  }

  /// Clear all state
  void clear() {
    _userId = null;
    _plans = [];
    _activePlan = null;
    _selectedPlan = null;
    _errorMessage = null;
    _isLoading = false;
    _isGenerating = false;
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

  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void _updateActivePlan() {
    // Find the most recent active plan (in progress)
    final inProgress = _plans.where((p) => p.isInProgress && p.isActive).toList();
    if (inProgress.isNotEmpty) {
      _activePlan = inProgress.first;
    } else {
      // Fallback to most recent in-progress plan
      final anyInProgress = _plans.where((p) => p.isInProgress).toList();
      if (anyInProgress.isNotEmpty) {
        anyInProgress.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _activePlan = anyInProgress.first;
      } else {
        _activePlan = null;
      }
    }
  }

  // ========== LOAD PLANS ==========

  /// Load all study plans from API
  Future<void> loadPlans() async {
    if (_userId == null || _userId!.isEmpty) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      _plans = await _apiService.getStudyPlans(_userId!);
      _updateActivePlan();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load study plans: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all plan data
  Future<void> refresh() async {
    await loadPlans();
  }

  // ========== GENERATE PLAN ==========

  /// Generate a new study plan
  Future<StudyPlanModel?> generatePlan({
    required List<StudySubject> subjects,
    required int availableHoursPerDay,
    required String preferredStudyTime,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return null;
    }

    try {
      _setGenerating(true);
      _errorMessage = null;

      final newPlan = await _apiService.generateStudyPlan(
        userId: _userId!,
        subjects: subjects,
        availableHoursPerDay: availableHoursPerDay,
        preferredStudyTime: preferredStudyTime,
      );

      // Add to local list
      _plans.insert(0, newPlan);
      _updateActivePlan();

      notifyListeners();
      return newPlan;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to generate study plan: $e';
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  // ========== DELETE PLAN ==========

  /// Delete a study plan
  Future<bool> deletePlan(int planId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _errorMessage = null;

      await _apiService.deleteStudyPlan(planId, _userId!);

      // Remove from local list
      _plans.removeWhere((p) => p.id == planId);

      // Clear selected if it was deleted
      if (_selectedPlan?.id == planId) {
        _selectedPlan = null;
      }

      // Update active plan
      if (_activePlan?.id == planId) {
        _updateActivePlan();
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete study plan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== SELECTION ==========

  /// Select a plan for detail view
  void selectPlan(StudyPlanModel plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// Clear selected plan
  void clearSelectedPlan() {
    _selectedPlan = null;
    notifyListeners();
  }

  /// Get plan by ID
  StudyPlanModel? getPlanById(int planId) {
    try {
      return _plans.firstWhere((p) => p.id == planId);
    } catch (_) {
      return null;
    }
  }
}
