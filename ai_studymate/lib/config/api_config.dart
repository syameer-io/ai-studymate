import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API configuration
///
/// Retrieves API keys and URLs from environment variables.
/// Never hardcode sensitive values here.

class ApiConfig {
  /// Gemini AI API key for summarization and flashcard generation
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  /// Laravel API base URL
  static String get laravelApiUrl {
    return dotenv.env['LARAVEL_API_URL'] ?? 'http://10.0.2.2:8000/api';
  }

  /// Firebase project ID (optional - mainly for reference)
  static String get firebaseProjectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  }
}
