/// Flashcard State Provider
///
/// Manages flashcard state and operations including:
/// - CRUD operations for flashcards
/// - AI-powered flashcard generation
/// - Study session management with spaced repetition
///
/// Usage:
///   Provider.of<FlashcardProvider>(context).flashcards
///   context.watch<FlashcardProvider>().isLoading

import 'package:flutter/foundation.dart';
import '../models/flashcard_model.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../utils/constants.dart';

class FlashcardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();

  // ========== STATE ==========

  /// All user's flashcards
  List<FlashcardModel> _flashcards = [];
  List<FlashcardModel> get flashcards => _flashcards;

  /// Filtered flashcards (by note or difficulty)
  List<FlashcardModel>? _filteredFlashcards;

  /// Get display flashcards (filtered or all)
  List<FlashcardModel> get displayFlashcards => _filteredFlashcards ?? _flashcards;

  /// Current filter values
  String? _currentNoteFilter;
  String? get currentNoteFilter => _currentNoteFilter;

  String? _currentDifficultyFilter;
  String? get currentDifficultyFilter => _currentDifficultyFilter;

  // ========== STUDY SESSION STATE ==========

  /// Flashcards for current study session
  List<FlashcardModel> _studyDeck = [];
  List<FlashcardModel> get studyDeck => _studyDeck;

  /// Current position in study deck
  int _currentCardIndex = 0;
  int get currentCardIndex => _currentCardIndex;

  /// Get current card being studied
  FlashcardModel? get currentCard =>
      _studyDeck.isNotEmpty && _currentCardIndex < _studyDeck.length
          ? _studyDeck[_currentCardIndex]
          : null;

  /// Study session statistics
  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _incorrectCount = 0;
  int get incorrectCount => _incorrectCount;

  /// Whether a study session is active
  bool _isStudySessionActive = false;
  bool get isStudySessionActive => _isStudySessionActive;

  /// Whether study session is complete
  bool get isStudySessionComplete =>
      _isStudySessionActive && _currentCardIndex >= _studyDeck.length;

  /// Total cards in current study session
  int get studyDeckSize => _studyDeck.length;

  /// Progress through study session (0.0 to 1.0)
  double get studyProgress =>
      _studyDeck.isEmpty ? 0.0 : _currentCardIndex / _studyDeck.length;

  // ========== LOADING STATES ==========

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // ========== ERROR STATE ==========

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========== USER STATE ==========

  String? _userId;
  String? get userId => _userId;

  // ========== CONVENIENCE GETTERS ==========

  bool get hasFlashcards => _flashcards.isNotEmpty;
  int get flashcardCount => _flashcards.length;
  int get displayCount => displayFlashcards.length;

  /// Get cards due for review
  List<FlashcardModel> get dueFlashcards =>
      _flashcards.where((fc) => fc.isDueForReview).toList();

  int get dueCount => dueFlashcards.length;

  /// Get difficulty distribution
  Map<String, int> get difficultyDistribution {
    final counts = <String, int>{
      AppConstants.difficultyEasy: 0,
      AppConstants.difficultyMedium: 0,
      AppConstants.difficultyHard: 0,
    };

    for (final fc in _flashcards) {
      counts[fc.difficulty] = (counts[fc.difficulty] ?? 0) + 1;
    }

    return counts;
  }

  /// Get overall accuracy across all cards
  double get overallAccuracy {
    int totalReviewed = 0;
    int totalCorrect = 0;

    for (final fc in _flashcards) {
      totalReviewed += fc.timesReviewed;
      totalCorrect += fc.timesCorrect;
    }

    if (totalReviewed == 0) return 0.0;
    return totalCorrect / totalReviewed;
  }

  /// Get total reviews across all cards
  int get totalReviews =>
      _flashcards.fold(0, (sum, fc) => sum + fc.timesReviewed);

  // ========== INITIALIZATION ==========

  /// Initialize provider with user ID
  void initialize(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _flashcards = [];
      _filteredFlashcards = null;
      loadFlashcards();
    }
  }

  /// Clear all data (call on logout)
  void clear() {
    _userId = null;
    _flashcards = [];
    _filteredFlashcards = null;
    _studyDeck = [];
    _currentCardIndex = 0;
    _correctCount = 0;
    _incorrectCount = 0;
    _isStudySessionActive = false;
    _currentNoteFilter = null;
    _currentDifficultyFilter = null;
    _errorMessage = null;
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

  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  // ========== LOAD FLASHCARDS ==========

  /// Load all flashcards for current user
  Future<void> loadFlashcards() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      _flashcards = await _firestoreService.getUserFlashcards(_userId!);
      _applyFilters();
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '${ErrorMessages.flashcardLoadFailed}: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh flashcards (for pull-to-refresh)
  Future<void> refresh() async {
    await loadFlashcards();
  }

  // ========== CREATE FLASHCARDS ==========

  /// Create a new flashcard manually
  ///
  /// Returns true on success, false on failure.
  Future<bool> createFlashcard({
    required String question,
    required String answer,
    required String difficulty,
    String? noteId,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      _setSaving(true);
      _errorMessage = null;

      final flashcard = FlashcardModel(
        id: '',
        userId: _userId!,
        noteId: noteId,
        question: question,
        answer: answer,
        difficulty: difficulty,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedFlashcard = await _firestoreService.createFlashcard(flashcard);

      // Add to local list
      _flashcards.insert(0, savedFlashcard);
      _applyFilters();

      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '${ErrorMessages.flashcardSaveFailed}: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Generate flashcards from note content using AI
  ///
  /// [noteId] - ID of the source note
  /// [noteContent] - Text content to generate flashcards from
  /// [count] - Number of flashcards to generate (default: 10)
  ///
  /// Returns true on success, false on failure.
  Future<bool> generateFlashcardsFromNote({
    required String noteId,
    required String noteContent,
    int count = 10,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      _setGenerating(true);
      _errorMessage = null;

      // Generate flashcards using Gemini
      final generatedCards = await _geminiService.generateFlashcards(
        noteContent,
        count: count,
      );

      if (generatedCards.isEmpty) {
        _errorMessage = ErrorMessages.noFlashcardsGenerated;
        return false;
      }

      // Convert to FlashcardModels
      final now = DateTime.now();
      final flashcards = generatedCards.map((card) => FlashcardModel(
            id: '',
            userId: _userId!,
            noteId: noteId,
            question: card['question']!,
            answer: card['answer']!,
            difficulty: card['difficulty']!,
            createdAt: now,
            updatedAt: now,
          )).toList();

      // Save batch to Firestore
      final savedFlashcards =
          await _firestoreService.createFlashcardsBatch(flashcards);

      // Add to local list
      _flashcards.insertAll(0, savedFlashcards);
      _applyFilters();

      return true;
    } on GeminiException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = 'Flashcards generated but failed to save: ${e.message}';
      return false;
    } catch (e) {
      _errorMessage = '${ErrorMessages.flashcardGenerationFailed}: $e';
      return false;
    } finally {
      _setGenerating(false);
    }
  }

  // ========== UPDATE FLASHCARDS ==========

  /// Update an existing flashcard
  ///
  /// Returns true on success, false on failure.
  Future<bool> updateFlashcard(FlashcardModel flashcard) async {
    try {
      _setSaving(true);
      _errorMessage = null;

      await _firestoreService.updateFlashcard(flashcard);

      // Update local list
      final index = _flashcards.indexWhere((fc) => fc.id == flashcard.id);
      if (index != -1) {
        _flashcards[index] = flashcard.copyWith(updatedAt: DateTime.now());
        _applyFilters();
      }

      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '${ErrorMessages.flashcardSaveFailed}: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ========== DELETE FLASHCARDS ==========

  /// Delete a flashcard
  ///
  /// Returns true on success, false on failure.
  Future<bool> deleteFlashcard(String flashcardId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _firestoreService.deleteFlashcard(flashcardId);

      // Remove from local list
      _flashcards.removeWhere((fc) => fc.id == flashcardId);
      _applyFilters();

      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = '${ErrorMessages.flashcardDeleteFailed}: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== FILTERING ==========

  /// Filter flashcards by note ID
  void filterByNote(String? noteId) {
    _currentNoteFilter = noteId;
    _applyFilters();
  }

  /// Filter flashcards by difficulty
  void filterByDifficulty(String? difficulty) {
    _currentDifficultyFilter = difficulty;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _currentNoteFilter = null;
    _currentDifficultyFilter = null;
    _filteredFlashcards = null;
    notifyListeners();
  }

  /// Apply current filters to flashcard list
  void _applyFilters() {
    if (_currentNoteFilter == null && _currentDifficultyFilter == null) {
      _filteredFlashcards = null;
    } else {
      _filteredFlashcards = _flashcards.where((fc) {
        if (_currentNoteFilter != null && fc.noteId != _currentNoteFilter) {
          return false;
        }
        if (_currentDifficultyFilter != null &&
            fc.difficulty != _currentDifficultyFilter) {
          return false;
        }
        return true;
      }).toList();
    }
    notifyListeners();
  }

  /// Get flashcards for a specific note
  List<FlashcardModel> getFlashcardsForNote(String noteId) {
    return _flashcards.where((fc) => fc.noteId == noteId).toList();
  }

  /// Get count of flashcards for a note
  int getFlashcardCountForNote(String noteId) {
    return _flashcards.where((fc) => fc.noteId == noteId).length;
  }

  // ========== STUDY SESSION ==========

  /// Start a new study session
  ///
  /// [noteId] - Optional: only study cards from this note
  /// [difficulty] - Optional: only study cards of this difficulty
  /// [shuffled] - Whether to shuffle the deck (default: true)
  void startStudySession({
    String? noteId,
    String? difficulty,
    bool shuffled = true,
    bool dueOnly = false,
  }) {
    // Build study deck based on filters
    List<FlashcardModel> deck = List.from(_flashcards);

    if (noteId != null) {
      deck = deck.where((fc) => fc.noteId == noteId).toList();
    }

    if (difficulty != null) {
      deck = deck.where((fc) => fc.difficulty == difficulty).toList();
    }

    if (dueOnly) {
      deck = deck.where((fc) => fc.isDueForReview).toList();
    }

    if (shuffled) {
      deck.shuffle();
    }

    _studyDeck = deck;
    _currentCardIndex = 0;
    _correctCount = 0;
    _incorrectCount = 0;
    _isStudySessionActive = true;

    notifyListeners();
  }

  /// Record an answer for the current card
  ///
  /// [wasCorrect] - Whether the user got it right
  Future<void> recordAnswer(bool wasCorrect) async {
    if (!_isStudySessionActive || currentCard == null) return;

    // Update statistics
    if (wasCorrect) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    // Calculate next review date using spaced repetition
    final now = DateTime.now();
    final nextReviewAt = _calculateNextReview(currentCard!, wasCorrect);

    // Update card statistics in Firestore
    try {
      await _firestoreService.updateFlashcardStats(
        currentCard!.id,
        wasCorrect: wasCorrect,
        reviewedAt: now,
        nextReviewAt: nextReviewAt,
      );

      // Update local state
      final index = _flashcards.indexWhere((fc) => fc.id == currentCard!.id);
      if (index != -1) {
        _flashcards[index] = _flashcards[index].copyWith(
          timesReviewed: _flashcards[index].timesReviewed + 1,
          timesCorrect: wasCorrect
              ? _flashcards[index].timesCorrect + 1
              : _flashcards[index].timesCorrect,
          lastReviewedAt: now,
          nextReviewAt: nextReviewAt,
        );
      }
    } catch (e) {
      debugPrint('Failed to update flashcard stats: $e');
    }

    // Move to next card
    _currentCardIndex++;
    notifyListeners();
  }

  /// Calculate next review date using SM-2 inspired algorithm
  DateTime _calculateNextReview(FlashcardModel card, bool wasCorrect) {
    final now = DateTime.now();

    if (!wasCorrect) {
      // If wrong, review again soon
      return now.add(const Duration(minutes: 10));
    }

    // Calculate interval based on past performance
    final accuracy = card.timesReviewed > 0
        ? (card.timesCorrect + 1) / (card.timesReviewed + 1)
        : 1.0;

    int daysUntilNext;
    if (card.timesReviewed == 0) {
      daysUntilNext = 1; // First time correct: review tomorrow
    } else if (accuracy >= 0.9) {
      daysUntilNext = 7; // High accuracy: weekly review
    } else if (accuracy >= 0.7) {
      daysUntilNext = 3; // Medium accuracy: every 3 days
    } else {
      daysUntilNext = 1; // Low accuracy: daily review
    }

    return now.add(Duration(days: daysUntilNext));
  }

  /// Skip to next card without recording
  void nextCard() {
    if (_currentCardIndex < _studyDeck.length - 1) {
      _currentCardIndex++;
      notifyListeners();
    }
  }

  /// Go back to previous card
  void previousCard() {
    if (_currentCardIndex > 0) {
      _currentCardIndex--;
      notifyListeners();
    }
  }

  /// End the current study session
  void endStudySession() {
    _isStudySessionActive = false;
    _studyDeck = [];
    _currentCardIndex = 0;
    notifyListeners();
  }

  /// Get study session accuracy
  double get studySessionAccuracy {
    final total = _correctCount + _incorrectCount;
    if (total == 0) return 0.0;
    return _correctCount / total;
  }

  @override
  void dispose() {
    _geminiService.dispose();
    super.dispose();
  }
}
