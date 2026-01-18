/// App-wide constants
///
/// Centralized location for all constant values used throughout the app.
/// This helps maintain consistency and makes it easy to update values.

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ========== Route Names ==========
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeNotes = '/notes';
  static const String routeNoteDetail = '/note-detail';
  static const String routeCreateNote = '/create-note';
  static const String routeFlashcards = '/flashcards';
  static const String routeStudy = '/study';
  static const String routeExams = '/exams';
  static const String routeCreateExam = '/create-exam';
  static const String routeRecorder = '/recorder';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';

  // ========== Firestore Collections ==========
  static const String collectionUsers = 'users';
  static const String collectionNotes = 'notes';
  static const String collectionFlashcards = 'flashcards';
  static const String collectionStudySessions = 'study_sessions';

  // ========== Firebase Storage Paths ==========
  static const String storageNoteImages = 'note_images';
  static const String storageProfileImages = 'profile_images';
  static const String storageAudioFiles = 'audio_files';

  // ========== Validation Constraints ==========
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxContentLength = 50000;
  static const int maxFlashcardsPerNote = 50;
  static const int maxAudioDurationSeconds = 300; // 5 minutes

  // ========== UI Constants ==========
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const int snackBarDurationMs = 3000;

  // ========== Animation Durations ==========
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ========== Flashcard Difficulty ==========
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
}

/// Error messages used throughout the app
class ErrorMessages {
  ErrorMessages._();

  // Authentication errors
  static const String emailRequired = 'Please enter your email';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Please enter your password';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String nameRequired = 'Please enter your name';
  static const String loginFailed = 'Login failed. Please try again.';
  static const String registerFailed = 'Registration failed. Please try again.';
  static const String googleSignInCancelled = 'Google sign-in was cancelled';
  static const String googleSignInFailed = 'Google sign-in failed. Please try again.';

  // Note errors
  static const String titleRequired = 'Please enter a title';
  static const String contentRequired = 'Please enter some content';
  static const String noteLoadFailed = 'Failed to load notes';
  static const String noteSaveFailed = 'Failed to save note';
  static const String noteDeleteFailed = 'Failed to delete note';

  // OCR errors
  static const String ocrFailed = 'Failed to extract text from image';
  static const String noTextFound = 'No text found in image';

  // AI/Gemini errors
  static const String summaryGenerationFailed = 'Failed to generate summary';
  static const String summaryContentTooShort = 'Note is too short to summarize. Add more content first.';
  static const String summaryContentEmpty = 'Cannot summarize empty notes';
  static const String aiServiceBusy = 'AI service is temporarily busy. Please try again in a moment.';
  static const String aiServiceError = 'AI service error. Please try again later.';
  static const String aiNetworkError = 'Network error. Please check your connection and try again.';

  // Flashcard errors
  static const String questionRequired = 'Please enter a question';
  static const String answerRequired = 'Please enter an answer';
  static const String flashcardLoadFailed = 'Failed to load flashcards';
  static const String flashcardSaveFailed = 'Failed to save flashcard';
  static const String flashcardDeleteFailed = 'Failed to delete flashcard';
  static const String flashcardGenerationFailed = 'Failed to generate flashcards. Please try again.';
  static const String flashcardContentTooShort = 'Note content is too short to generate flashcards.';
  static const String noFlashcardsGenerated = 'No flashcards could be generated from this content.';

  // Exam errors
  static const String examNameRequired = 'Please enter an exam name';
  static const String examSubjectRequired = 'Please enter a subject';
  static const String examDateRequired = 'Please select an exam date';
  static const String examLoadFailed = 'Failed to load exams';
  static const String examSaveFailed = 'Failed to save exam';
  static const String examDeleteFailed = 'Failed to delete exam';
  static const String examUpdateFailed = 'Failed to update exam';
  static const String examNotFound = 'Exam not found';

  // Speech/Voice errors
  static const String speechNotAvailable = 'Speech recognition is not available on this device';
  static const String speechPermissionDenied = 'Microphone permission denied. Please enable in settings.';
  static const String speechNoTextRecognized = 'No speech was recognized. Please try again.';
  static const String recordingFailed = 'Failed to start recording';
  static const String recordingStopFailed = 'Failed to stop recording';
  static const String audioUploadFailed = 'Failed to upload audio file';
  static const String audioPlaybackFailed = 'Failed to play audio';
  static const String maxRecordingDurationReached = 'Maximum recording duration reached (5 minutes)';
  static const String transcriptionFailed = 'Failed to transcribe audio. Please try again.';
  static const String transcriptionEmpty = 'No speech detected in recording. Please speak clearly and try again.';

  // General errors
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
}

/// Success messages
class SuccessMessages {
  SuccessMessages._();

  static const String accountCreated = 'Account created successfully!';
  static const String loginSuccess = 'Welcome back!';
  static const String logoutSuccess = 'Logged out successfully';
  static const String noteSaved = 'Note saved successfully';
  static const String noteDeleted = 'Note deleted';
  static const String flashcardCreated = 'Flashcard created';
  static const String passwordResetSent = 'Password reset email sent';
  static const String summaryGenerated = 'Summary generated successfully!';
  static const String summaryUpdated = 'Summary updated';
  static const String flashcardsGenerated = 'Flashcards generated successfully!';
  static const String flashcardSaved = 'Flashcard saved';
  static const String flashcardDeleted = 'Flashcard deleted';
  static const String studySessionComplete = 'Great job! Study session complete.';

  // Exam messages
  static const String examCreated = 'Exam created successfully';
  static const String examUpdated = 'Exam updated successfully';
  static const String examDeleted = 'Exam deleted';
  static const String examMarkedComplete = 'Exam marked as completed';
  static const String examMarkedIncomplete = 'Exam marked as incomplete';

  // Voice recording
  static const String recordingComplete = 'Recording complete';
  static const String voiceNoteSaved = 'Voice note saved successfully';
}
