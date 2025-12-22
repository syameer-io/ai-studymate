/// Flashcard Model
///
/// Represents a study flashcard in the application.
/// Maps to Firestore documents in the 'flashcards' collection.
/// Supports spaced repetition tracking for optimized study sessions.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme_config.dart';
import '../utils/constants.dart';

class FlashcardModel {
  /// Firestore document ID
  final String id;

  /// Owner's Firebase user ID
  final String userId;

  /// Link to source note (optional)
  final String? noteId;

  /// Question text
  final String question;

  /// Answer text
  final String answer;

  /// Difficulty level: 'easy', 'medium', 'hard'
  final String difficulty;

  /// Number of times this card has been reviewed
  final int timesReviewed;

  /// Number of times answered correctly
  final int timesCorrect;

  /// Last review timestamp (null if never reviewed)
  final DateTime? lastReviewedAt;

  /// Next scheduled review for spaced repetition (null if never reviewed)
  final DateTime? nextReviewAt;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  const FlashcardModel({
    required this.id,
    required this.userId,
    this.noteId,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.timesReviewed = 0,
    this.timesCorrect = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create FlashcardModel from Firestore DocumentSnapshot
  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel.fromMap(data, doc.id);
  }

  /// Create FlashcardModel from Map (Firestore data)
  factory FlashcardModel.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardModel(
      id: id,
      userId: map['userId'] ?? '',
      noteId: map['noteId'],
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      difficulty: map['difficulty'] ?? AppConstants.difficultyMedium,
      timesReviewed: map['timesReviewed'] ?? 0,
      timesCorrect: map['timesCorrect'] ?? 0,
      lastReviewedAt: _parseTimestamp(map['lastReviewedAt']),
      nextReviewAt: _parseTimestamp(map['nextReviewAt']),
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Helper to parse Firestore Timestamp or DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'timesReviewed': timesReviewed,
      'timesCorrect': timesCorrect,
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
      'nextReviewAt': nextReviewAt != null
          ? Timestamp.fromDate(nextReviewAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  FlashcardModel copyWith({
    String? id,
    String? userId,
    String? noteId,
    String? question,
    String? answer,
    String? difficulty,
    int? timesReviewed,
    int? timesCorrect,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Get accuracy percentage (0.0 to 1.0)
  double get accuracy {
    if (timesReviewed == 0) return 0.0;
    return timesCorrect / timesReviewed;
  }

  /// Get accuracy as percentage string
  String get accuracyPercent {
    return '${(accuracy * 100).toStringAsFixed(0)}%';
  }

  /// Check if this card has never been reviewed
  bool get isNew => timesReviewed == 0;

  /// Check if card is due for review (spaced repetition)
  bool get isDueForReview {
    if (nextReviewAt == null) return true; // Never reviewed
    return DateTime.now().isAfter(nextReviewAt!);
  }

  /// Get display-friendly difficulty
  String get difficultyDisplay {
    switch (difficulty) {
      case AppConstants.difficultyEasy:
        return 'Easy';
      case AppConstants.difficultyMedium:
        return 'Medium';
      case AppConstants.difficultyHard:
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  /// Get color for difficulty level
  Color get difficultyColor {
    switch (difficulty) {
      case AppConstants.difficultyEasy:
        return AppColors.success;
      case AppConstants.difficultyMedium:
        return AppColors.warning;
      case AppConstants.difficultyHard:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  /// Get question preview (first 80 characters)
  String get questionPreview {
    if (question.length <= 80) return question;
    return '${question.substring(0, 80)}...';
  }

  /// Get answer preview (first 100 characters)
  String get answerPreview {
    if (answer.length <= 100) return answer;
    return '${answer.substring(0, 100)}...';
  }

  /// Get formatted last reviewed date
  String get formattedLastReviewed {
    if (lastReviewedAt == null) return 'Never';
    return DateFormat('MMM d, yyyy').format(lastReviewedAt!);
  }

  /// Get formatted next review date
  String get formattedNextReview {
    if (nextReviewAt == null) return 'Review now';
    final now = DateTime.now();
    final difference = nextReviewAt!.difference(now);

    if (difference.isNegative) return 'Due now';
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Tomorrow';
    if (difference.inDays < 7) return 'In ${difference.inDays} days';
    return DateFormat('MMM d').format(nextReviewAt!);
  }

  /// Get formatted creation date
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  /// Check if linked to a note
  bool get isLinkedToNote => noteId != null && noteId!.isNotEmpty;

  @override
  String toString() {
    return 'FlashcardModel(id: $id, question: ${questionPreview}, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlashcardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
