/// Notes State Provider
///
/// Manages notes state and operations.
/// Uses ChangeNotifier to notify widgets when state changes.
///
/// Usage:
///   Provider.of<NotesProvider>(context).notes
///   context.watch<NotesProvider>().isLoading

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';

class NotesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final OcrService _ocrService = OcrService();
  final PdfService _pdfService = PdfService();
  final GeminiService _geminiService = GeminiService();
  final SpeechService _speechService = SpeechService();

  // List of user's notes
  List<NoteModel> _notes = [];
  List<NoteModel> get notes => _notes;

  // Currently selected note (for detail view)
  NoteModel? _selectedNote;
  NoteModel? get selectedNote => _selectedNote;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessingFile = false;
  bool get isProcessingFile => _isProcessingFile;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isGeneratingSummary = false;
  bool get isGeneratingSummary => _isGeneratingSummary;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Current user ID
  String? _userId;
  String? get userId => _userId;

  // Convenience getters
  bool get hasNotes => _notes.isNotEmpty;
  int get noteCount => _notes.length;

  /// Initialize provider with user ID
  void initialize(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _notes = [];
      loadNotes();
    }
  }

  /// Clear all data (call on logout)
  void clear() {
    _userId = null;
    _notes = [];
    _selectedNote = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set processing state
  void _setProcessing(bool value) {
    _isProcessingFile = value;
    notifyListeners();
  }

  /// Set saving state
  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  /// Set generating summary state
  void _setGeneratingSummary(bool value) {
    _isGeneratingSummary = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ========== LOAD NOTES ==========

  /// Load all notes for current user
  Future<void> loadNotes() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      _notes = await _firestoreService.getUserNotes(_userId!);
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load notes: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh notes (for pull-to-refresh)
  Future<void> refresh() async {
    await loadNotes();
  }

  // ========== CREATE NOTES ==========

  /// Create a text-only note
  ///
  /// Returns true on success, false on failure.
  Future<bool> createTextNote({
    required String title,
    required String content,
    String? subject,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      _setSaving(true);
      _errorMessage = null;

      // Create note model
      final note = NoteModel(
        id: '', // Will be set by Firestore
        userId: _userId!,
        title: title,
        content: content,
        subject: subject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final savedNote = await _firestoreService.createNote(note);

      // Add to local list
      _notes.insert(0, savedNote);
      notifyListeners();

      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create note: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Create a note from an image with OCR
  ///
  /// Returns true on success, false on failure.
  Future<bool> createNoteFromImage({
    required String title,
    required File imageFile,
    String? subject,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      _setProcessing(true);
      _errorMessage = null;

      // Extract text from image
      final extractedText = await _ocrService.extractTextFromImage(imageFile);

      // Upload image to storage
      _setSaving(true);
      final imageUrl = await _storageService.uploadNoteImage(
        userId: _userId!,
        file: imageFile,
      );

      // Create note model
      final note = NoteModel(
        id: '',
        userId: _userId!,
        title: title,
        content: extractedText,
        fileUrl: imageUrl,
        fileType: 'image',
        subject: subject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final savedNote = await _firestoreService.createNote(note);

      // Add to local list
      _notes.insert(0, savedNote);
      notifyListeners();

      return true;
    } on OcrException catch (e) {
      _errorMessage = e.message;
      return false;
    } on StorageException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create note: $e';
      return false;
    } finally {
      _setProcessing(false);
      _setSaving(false);
    }
  }

  /// Create a note from a PDF file
  ///
  /// Returns true on success, false on failure.
  Future<bool> createNoteFromPdf({
    required String title,
    required File pdfFile,
    String? subject,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    try {
      _setProcessing(true);
      _errorMessage = null;

      // Extract text from PDF
      final extractedText = await _pdfService.extractTextFromPdf(pdfFile);

      // Upload PDF to storage
      _setSaving(true);
      final pdfUrl = await _storageService.uploadNotePdf(
        userId: _userId!,
        file: pdfFile,
      );

      // Create note model
      final note = NoteModel(
        id: '',
        userId: _userId!,
        title: title,
        content: extractedText,
        fileUrl: pdfUrl,
        fileType: 'pdf',
        subject: subject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final savedNote = await _firestoreService.createNote(note);

      // Add to local list
      _notes.insert(0, savedNote);
      notifyListeners();

      return true;
    } on PdfException catch (e) {
      _errorMessage = e.message;
      return false;
    } on StorageException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create note: $e';
      return false;
    } finally {
      _setProcessing(false);
      _setSaving(false);
    }
  }

  /// Create a note from an audio recording with transcription
  ///
  /// [audioFile] - The recorded audio file
  /// [transcription] - The transcribed text from speech
  /// [title] - Note title
  /// [subject] - Optional subject tag
  ///
  /// Returns true on success, false on failure.
  Future<bool> createNoteFromAudio({
    required File audioFile,
    required String transcription,
    required String title,
    String? subject,
  }) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      return false;
    }

    if (transcription.trim().isEmpty) {
      _errorMessage = 'No transcription provided';
      return false;
    }

    try {
      _setProcessing(true);
      _errorMessage = null;

      // Upload audio to Firebase Storage
      _setSaving(true);
      final audioUrl = await _storageService.uploadNoteAudio(
        userId: _userId!,
        file: audioFile,
      );

      // Create note model with audio fileType
      final note = NoteModel(
        id: '',
        userId: _userId!,
        title: title,
        content: transcription,
        fileUrl: audioUrl,
        fileType: 'audio',
        subject: subject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final savedNote = await _firestoreService.createNote(note);

      // Add to local list
      _notes.insert(0, savedNote);
      notifyListeners();

      return true;
    } on StorageException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create note from audio: $e';
      return false;
    } finally {
      _setProcessing(false);
      _setSaving(false);
    }
  }

  // ========== TEXT EXTRACTION (for preview) ==========

  /// Extract text from an image file (for preview before saving)
  ///
  /// Returns extracted text or null on failure.
  Future<String?> extractTextFromImage(File imageFile) async {
    try {
      _setProcessing(true);
      _errorMessage = null;

      final text = await _ocrService.extractTextFromImage(imageFile);
      return text;
    } on OcrException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to extract text: $e';
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Extract text from a PDF file (for preview before saving)
  ///
  /// Returns extracted text or null on failure.
  Future<String?> extractTextFromPdf(File pdfFile) async {
    try {
      _setProcessing(true);
      _errorMessage = null;

      final text = await _pdfService.extractTextFromPdf(pdfFile);
      return text;
    } on PdfException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to extract text: $e';
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  // ========== UPDATE NOTES ==========

  /// Update an existing note
  ///
  /// Returns true on success, false on failure.
  Future<bool> updateNote(NoteModel note) async {
    try {
      _setSaving(true);
      _errorMessage = null;

      await _firestoreService.updateNote(note);

      // Update local list
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(updatedAt: DateTime.now());
        // Move to top of list (most recent)
        final updatedNote = _notes.removeAt(index);
        _notes.insert(0, updatedNote);
        notifyListeners();
      }

      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update note: $e';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Update note summary
  Future<bool> updateNoteSummary(String noteId, String summary) async {
    try {
      await _firestoreService.updateNoteSummary(noteId, summary);

      // Update local list
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(summary: summary);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update summary: $e';
      return false;
    }
  }

  /// Generate AI summary for a note
  ///
  /// [noteId] - The ID of the note to summarize
  ///
  /// Returns true on success, false on failure.
  Future<bool> generateNoteSummary(String noteId) async {
    // Find the note
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      _errorMessage = 'Note not found';
      return false;
    }

    final note = _notes[noteIndex];

    // Validate content
    if (note.content.trim().isEmpty) {
      _errorMessage = 'Cannot summarize empty notes';
      return false;
    }

    // Check minimum content length
    if (note.content.trim().length < 50) {
      _errorMessage = 'Note is too short to summarize. Add more content first.';
      return false;
    }

    try {
      _setGeneratingSummary(true);
      _errorMessage = null;

      // Generate summary using Gemini
      final summary = await _geminiService.generateSummary(note.content);

      // Save to Firestore
      await _firestoreService.updateNoteSummary(noteId, summary);

      // Update local state
      _notes[noteIndex] = note.copyWith(summary: summary);

      // Update selected note if it matches
      if (_selectedNote?.id == noteId) {
        _selectedNote = _notes[noteIndex];
      }

      notifyListeners();
      return true;
    } on GeminiException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = 'Summary generated but failed to save: ${e.message}';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to generate summary: $e';
      return false;
    } finally {
      _setGeneratingSummary(false);
    }
  }

  // ========== DELETE NOTES ==========

  /// Delete a note
  ///
  /// Returns true on success, false on failure.
  Future<bool> deleteNote(String noteId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Find note to get file URL
      final note = _notes.firstWhere(
        (n) => n.id == noteId,
        orElse: () => throw Exception('Note not found'),
      );

      // Delete from Firestore
      await _firestoreService.deleteNote(noteId);

      // Delete file from Storage if exists
      if (note.hasFile) {
        await _storageService.deleteFile(note.fileUrl!);
      }

      // Remove from local list
      _notes.removeWhere((n) => n.id == noteId);

      // Clear selected note if it was deleted
      if (_selectedNote?.id == noteId) {
        _selectedNote = null;
      }

      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete note: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== SELECTION ==========

  /// Set selected note for detail view
  void selectNote(NoteModel note) {
    _selectedNote = note;
    notifyListeners();
  }

  /// Clear selected note
  void clearSelectedNote() {
    _selectedNote = null;
    notifyListeners();
  }

  // ========== SEARCH ==========

  /// Search notes by title or content
  Future<List<NoteModel>> searchNotes(String query) async {
    if (_userId == null || query.isEmpty) return [];

    try {
      return await _firestoreService.searchNotes(_userId!, query);
    } catch (e) {
      return [];
    }
  }

  /// Get notes filtered by subject
  List<NoteModel> getNotesBySubject(String subject) {
    return _notes.where((note) => note.subject == subject).toList();
  }

  /// Get all unique subjects
  List<String> get subjects {
    return _notes
        .where((note) => note.subject != null && note.subject!.isNotEmpty)
        .map((note) => note.subject!)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _geminiService.dispose();
    _speechService.dispose();
    super.dispose();
  }
}
