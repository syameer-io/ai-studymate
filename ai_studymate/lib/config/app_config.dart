// Application-wide configuration constants
//
// This file contains all configuration values used throughout the app.
// Never put API keys directly here - use environment variables instead.

class AppConfig {
  // App Information
  static const String appName = 'AI StudyMate';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered study assistant';

  // Team Information (for credits)
  static const String teamName = 'Cyborg Enterprise';
  static const List<String> teamMembers = [
    'Syameer (CEO)',
    'Izzah Khayreen (Project Manager)',
    'Dinie Maisara (Server & Security)',
  ];

  // Feature Flags
  static const bool enableGoogleSignIn = true;
  static const bool enableVoiceRecording = true;
  static const bool enableOfflineMode = false; // Future feature

  // Limits
  static const int maxNotesPerUser = 1000;
  static const int maxFlashcardsPerNote = 50;
  static const int maxAudioRecordingSeconds = 300; // 5 minutes

  // API Timeouts (in seconds)
  static const int apiConnectTimeout = 30;
  static const int apiReceiveTimeout = 30;
}
