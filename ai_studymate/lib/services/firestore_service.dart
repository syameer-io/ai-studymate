/// Firestore Service
///
/// Handles Firestore CRUD operations for notes.
/// Uses singleton pattern for consistent access.
///
/// Usage:
///   final firestoreService = FirestoreService();
///   final notes = await firestoreService.getUserNotes(userId);

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';
import '../utils/constants.dart';

/// Custom exception for Firestore errors
class FirestoreException implements Exception {
  final String message;
  final String? code;

  const FirestoreException(this.message, [this.code]);

  @override
  String toString() => message;
}

class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get notes collection reference
  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection(AppConstants.collectionNotes);

  /// Get flashcards collection reference
  CollectionReference<Map<String, dynamic>> get _flashcardsCollection =>
      _firestore.collection(AppConstants.collectionFlashcards);

  // ========== NOTES CRUD ==========

  /// Create a new note
  ///
  /// [note] - NoteModel to create (id will be auto-generated)
  ///
  /// Returns the created note with Firestore-generated ID
  /// Throws [FirestoreException] on failure
  Future<NoteModel> createNote(NoteModel note) async {
    try {
      // Add document and get reference
      final docRef = await _notesCollection.add(note.toMap());

      // Return note with the generated ID
      return note.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteSaveFailed}: $e');
    }
  }

  /// Get all notes for a user (ordered by most recent)
  ///
  /// [userId] - User's Firebase UID
  ///
  /// Returns list of notes sorted by updatedAt descending
  Future<List<NoteModel>> getUserNotes(String userId) async {
    try {
      // Fetch notes without orderBy to avoid requiring a composite index
      // Sort locally instead for simplicity
      final snapshot = await _notesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final notes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();

      // Sort locally by updatedAt (most recent first)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notes;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteLoadFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteLoadFailed}: $e');
    }
  }

  /// Stream of user's notes (for real-time updates)
  ///
  /// [userId] - User's Firebase UID
  ///
  /// Returns a stream of note lists sorted by updatedAt descending
  Stream<List<NoteModel>> streamUserNotes(String userId) {
    return _notesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();
      // Sort locally by updatedAt (most recent first)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    });
  }

  /// Get a single note by ID
  ///
  /// [noteId] - Firestore document ID
  ///
  /// Returns the note or null if not found
  Future<NoteModel?> getNoteById(String noteId) async {
    try {
      final doc = await _notesCollection.doc(noteId).get();

      if (!doc.exists) {
        return null;
      }

      return NoteModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to load note',
        e.code,
      );
    } catch (e) {
      throw FirestoreException('Failed to load note: $e');
    }
  }

  /// Update an existing note
  ///
  /// [note] - NoteModel with updated fields
  ///
  /// Throws [FirestoreException] on failure
  Future<void> updateNote(NoteModel note) async {
    try {
      // Update with new timestamp
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _notesCollection.doc(note.id).update(updatedNote.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteSaveFailed}: $e');
    }
  }

  /// Update specific fields of a note
  ///
  /// [noteId] - Document ID
  /// [fields] - Map of fields to update
  Future<void> updateNoteFields(
    String noteId,
    Map<String, dynamic> fields,
  ) async {
    try {
      // Always update the timestamp
      fields['updatedAt'] = Timestamp.now();
      await _notesCollection.doc(noteId).update(fields);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteSaveFailed}: $e');
    }
  }

  /// Update note summary
  ///
  /// [noteId] - Document ID
  /// [summary] - AI-generated summary
  Future<void> updateNoteSummary(String noteId, String summary) async {
    await updateNoteFields(noteId, {'summary': summary});
  }

  /// Delete a note
  ///
  /// [noteId] - Document ID to delete
  ///
  /// Throws [FirestoreException] on failure
  Future<void> deleteNote(String noteId) async {
    try {
      await _notesCollection.doc(noteId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteDeleteFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteDeleteFailed}: $e');
    }
  }

  /// Search notes by title or content
  ///
  /// [userId] - User's Firebase UID
  /// [query] - Search query string
  ///
  /// Note: Firestore doesn't support full-text search natively.
  /// This performs a client-side filter.
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    try {
      // Get all user's notes
      final notes = await getUserNotes(userId);

      if (query.isEmpty) return notes;

      final queryLower = query.toLowerCase();

      // Filter by title or content containing query
      return notes.where((note) {
        return note.title.toLowerCase().contains(queryLower) ||
            note.content.toLowerCase().contains(queryLower) ||
            (note.subject?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    } catch (e) {
      throw FirestoreException('Search failed: $e');
    }
  }

  /// Get notes by subject
  ///
  /// [userId] - User's Firebase UID
  /// [subject] - Subject to filter by
  Future<List<NoteModel>> getNotesBySubject(String userId, String subject) async {
    try {
      final snapshot = await _notesCollection
          .where('userId', isEqualTo: userId)
          .where('subject', isEqualTo: subject)
          .get();

      final notes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();

      // Sort locally by updatedAt (most recent first)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notes;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.noteLoadFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.noteLoadFailed}: $e');
    }
  }

  /// Get count of user's notes
  ///
  /// [userId] - User's Firebase UID
  Future<int> getNoteCount(String userId) async {
    try {
      final snapshot = await _notesCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ========== FLASHCARDS CRUD ==========

  /// Create a new flashcard
  ///
  /// [flashcard] - FlashcardModel to create (id will be auto-generated)
  ///
  /// Returns the created flashcard with Firestore-generated ID
  /// Throws [FirestoreException] on failure
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard) async {
    try {
      final docRef = await _flashcardsCollection.add(flashcard.toMap());
      return flashcard.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardSaveFailed}: $e');
    }
  }

  /// Create multiple flashcards in a batch (for AI generation)
  ///
  /// [flashcards] - List of FlashcardModels to create
  ///
  /// Returns list of created flashcards with Firestore-generated IDs
  Future<List<FlashcardModel>> createFlashcardsBatch(
    List<FlashcardModel> flashcards,
  ) async {
    try {
      final batch = _firestore.batch();
      final List<DocumentReference> refs = [];

      for (final flashcard in flashcards) {
        final docRef = _flashcardsCollection.doc();
        refs.add(docRef);
        batch.set(docRef, flashcard.toMap());
      }

      await batch.commit();

      // Return flashcards with their new IDs
      return List.generate(
        flashcards.length,
        (i) => flashcards[i].copyWith(id: refs[i].id),
      );
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardSaveFailed}: $e');
    }
  }

  /// Get all flashcards for a user
  ///
  /// [userId] - User's Firebase UID
  ///
  /// Returns list of flashcards sorted by updatedAt descending
  Future<List<FlashcardModel>> getUserFlashcards(String userId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final flashcards = snapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();

      // Sort locally by updatedAt (most recent first)
      flashcards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return flashcards;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardLoadFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardLoadFailed}: $e');
    }
  }

  /// Get flashcards linked to a specific note
  ///
  /// [userId] - User's Firebase UID
  /// [noteId] - Note document ID
  Future<List<FlashcardModel>> getFlashcardsByNote(
    String userId,
    String noteId,
  ) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('userId', isEqualTo: userId)
          .where('noteId', isEqualTo: noteId)
          .get();

      final flashcards = snapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();

      flashcards.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return flashcards;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardLoadFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardLoadFailed}: $e');
    }
  }

  /// Get flashcards by difficulty level
  ///
  /// [userId] - User's Firebase UID
  /// [difficulty] - 'easy', 'medium', or 'hard'
  Future<List<FlashcardModel>> getFlashcardsByDifficulty(
    String userId,
    String difficulty,
  ) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('userId', isEqualTo: userId)
          .where('difficulty', isEqualTo: difficulty)
          .get();

      final flashcards = snapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();

      flashcards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return flashcards;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardLoadFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardLoadFailed}: $e');
    }
  }

  /// Get flashcards due for review (spaced repetition)
  ///
  /// [userId] - User's Firebase UID
  Future<List<FlashcardModel>> getDueFlashcards(String userId) async {
    try {
      // Get all flashcards and filter client-side
      // (Firestore doesn't support OR with null comparison easily)
      final flashcards = await getUserFlashcards(userId);

      return flashcards.where((fc) => fc.isDueForReview).toList();
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardLoadFailed}: $e');
    }
  }

  /// Stream of user's flashcards (for real-time updates)
  ///
  /// [userId] - User's Firebase UID
  Stream<List<FlashcardModel>> streamUserFlashcards(String userId) {
    return _flashcardsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final flashcards = snapshot.docs
          .map((doc) => FlashcardModel.fromFirestore(doc))
          .toList();
      flashcards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return flashcards;
    });
  }

  /// Get a single flashcard by ID
  ///
  /// [flashcardId] - Firestore document ID
  Future<FlashcardModel?> getFlashcardById(String flashcardId) async {
    try {
      final doc = await _flashcardsCollection.doc(flashcardId).get();

      if (!doc.exists) {
        return null;
      }

      return FlashcardModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to load flashcard',
        e.code,
      );
    } catch (e) {
      throw FirestoreException('Failed to load flashcard: $e');
    }
  }

  /// Update an existing flashcard
  ///
  /// [flashcard] - FlashcardModel with updated fields
  Future<void> updateFlashcard(FlashcardModel flashcard) async {
    try {
      final updatedFlashcard = flashcard.copyWith(updatedAt: DateTime.now());
      await _flashcardsCollection
          .doc(flashcard.id)
          .update(updatedFlashcard.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardSaveFailed}: $e');
    }
  }

  /// Update flashcard study statistics after a review
  ///
  /// [flashcardId] - Document ID
  /// [wasCorrect] - Whether the answer was correct
  /// [reviewedAt] - When the review occurred
  /// [nextReviewAt] - When to review next (spaced repetition)
  Future<void> updateFlashcardStats(
    String flashcardId, {
    required bool wasCorrect,
    required DateTime reviewedAt,
    required DateTime nextReviewAt,
  }) async {
    try {
      await _flashcardsCollection.doc(flashcardId).update({
        'timesReviewed': FieldValue.increment(1),
        if (wasCorrect) 'timesCorrect': FieldValue.increment(1),
        'lastReviewedAt': Timestamp.fromDate(reviewedAt),
        'nextReviewAt': Timestamp.fromDate(nextReviewAt),
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardSaveFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardSaveFailed}: $e');
    }
  }

  /// Delete a flashcard
  ///
  /// [flashcardId] - Document ID to delete
  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _flashcardsCollection.doc(flashcardId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardDeleteFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardDeleteFailed}: $e');
    }
  }

  /// Delete all flashcards linked to a note
  ///
  /// [noteId] - Note document ID
  Future<void> deleteFlashcardsByNote(String noteId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('noteId', isEqualTo: noteId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException(
        ErrorMessages.flashcardDeleteFailed,
        e.code,
      );
    } catch (e) {
      throw FirestoreException('${ErrorMessages.flashcardDeleteFailed}: $e');
    }
  }

  /// Get count of user's flashcards
  ///
  /// [userId] - User's Firebase UID
  Future<int> getFlashcardCount(String userId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
