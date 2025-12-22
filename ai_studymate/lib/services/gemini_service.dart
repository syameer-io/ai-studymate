/// Gemini AI Service
///
/// Handles AI-powered text generation using Google Gemini.
/// Uses singleton pattern for consistent access across the app.
///
/// Usage:
///   final geminiService = GeminiService();
///   final summary = await geminiService.generateSummary(content);

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../utils/constants.dart';

/// Custom exception for Gemini API errors
class GeminiException implements Exception {
  final String message;
  final String? code;

  const GeminiException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Gemini AI Service for note summarization
class GeminiService {
  // Singleton pattern (matches existing services)
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Lazy-initialized Gemini models
  GenerativeModel? _model;
  GenerativeModel? _flashcardModel;

  // Configuration constants
  static const int _maxInputChars = 120000; // ~30k tokens, conservative limit
  static const int _maxOutputTokensSummary = 2048; // For summaries
  static const int _maxOutputTokensFlashcards = 8192; // For flashcards (needs more tokens)
  static const double _temperature = 0.7; // Balanced creativity

  /// Get or initialize the Gemini model for summaries
  GenerativeModel get model {
    if (_model == null) {
      final apiKey = ApiConfig.geminiApiKey;

      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: _maxOutputTokensSummary,
          temperature: _temperature,
        ),
      );
    }
    return _model!;
  }

  /// Get or initialize the Gemini model for flashcard generation (higher token limit)
  GenerativeModel get flashcardModel {
    if (_flashcardModel == null) {
      final apiKey = ApiConfig.geminiApiKey;

      _flashcardModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: _maxOutputTokensFlashcards,
          temperature: 0.5, // Lower temperature for more consistent JSON
        ),
      );
    }
    return _flashcardModel!;
  }

  /// Generate a study-focused summary from note content
  ///
  /// [content] - The note text to summarize
  ///
  /// Returns a concise, study-oriented summary
  /// Throws [GeminiException] on failure
  Future<String> generateSummary(String content) async {
    // Validate input
    if (content.trim().isEmpty) {
      throw const GeminiException('Cannot summarize empty content');
    }

    // Truncate content if too long
    final truncatedContent = _truncateContent(content, _maxInputChars);

    try {
      // Build study-focused prompt
      final prompt = _buildSummaryPrompt(truncatedContent);

      // Generate content
      final response = await model.generateContent([Content.text(prompt)]);

      // Extract and validate response
      final summary = response.text;
      if (summary == null || summary.trim().isEmpty) {
        throw const GeminiException(
          'Failed to generate summary. Please try again.',
        );
      }

      return summary.trim();
    } on GenerativeAIException catch (e) {
      // Handle specific Gemini API errors
      throw _handleGeminiError(e);
    } on GeminiException {
      rethrow;
    } catch (e, stackTrace) {
      // Log unexpected errors for debugging
      debugPrint('[GeminiService] Unexpected error: $e');
      debugPrint('[GeminiService] Stack trace: $stackTrace');

      // Check if it's a network/connection error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('network') ||
          errorStr.contains('timeout')) {
        throw const GeminiException(
          'Network error. Please check your internet connection.',
          'NETWORK_ERROR',
        );
      }

      // For any other error, show the actual message for debugging
      throw GeminiException('AI Error: $e');
    }
  }

  /// Build an optimized prompt for study summarization
  String _buildSummaryPrompt(String content) {
    return '''
You are a study assistant helping students learn efficiently. Summarize the following study notes in a clear, concise format that aids retention and understanding.

Guidelines:
- Extract and highlight key concepts, definitions, and important facts
- Use bullet points for easy scanning
- Keep the summary focused and under 200 words
- Preserve any formulas, dates, or specific terminology
- Structure the summary logically (main ideas first, supporting details after)

Study Notes:
$content

Summary:''';
  }

  /// Truncate content to stay within token limits
  String _truncateContent(String content, int maxChars) {
    if (content.length <= maxChars) return content;

    // Truncate at a sentence boundary if possible
    final truncated = content.substring(0, maxChars);
    final lastPeriod = truncated.lastIndexOf('.');
    final lastNewline = truncated.lastIndexOf('\n');

    // Find the best cutoff point (prefer sentence end)
    int cutoff = maxChars;
    if (lastPeriod > maxChars - 500) {
      cutoff = lastPeriod + 1;
    } else if (lastNewline > maxChars - 500) {
      cutoff = lastNewline;
    }

    return '''${content.substring(0, cutoff)}

[Note: Content truncated for summarization. Original content is ${content.length} characters.]''';
  }

  /// Convert Gemini API errors to user-friendly messages
  GeminiException _handleGeminiError(GenerativeAIException e) {
    final message = e.message.toLowerCase();

    // Check for quota/rate limit errors (be more specific)
    if (message.contains('resource exhausted') ||
        message.contains('quota exceeded') ||
        message.contains('rate limit')) {
      return const GeminiException(
        'AI service quota exceeded. Please try again later.',
        'RATE_LIMIT',
      );
    }

    // Check for API key errors (be more specific)
    if (message.contains('api key not valid') ||
        message.contains('api_key_invalid') ||
        message.contains('invalid api key')) {
      return const GeminiException(
        'Invalid API key. Please check your configuration.',
        'AUTH_ERROR',
      );
    }

    // Check for safety/content blocking
    if (message.contains('blocked') ||
        message.contains('safety') ||
        message.contains('harm')) {
      return const GeminiException(
        'Content could not be processed due to safety filters.',
        'SAFETY_BLOCK',
      );
    }

    // Check for model not found
    if (message.contains('model') && message.contains('not found')) {
      return const GeminiException(
        'AI model not available. Please try again later.',
        'MODEL_ERROR',
      );
    }

    // Check for network errors
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection')) {
      return const GeminiException(
        'Network error. Please check your connection.',
        'NETWORK_ERROR',
      );
    }

    // Return the actual error message for debugging
    return GeminiException('Gemini API Error: ${e.message}');
  }

  // ========== FLASHCARD GENERATION ==========

  /// Generate flashcards from note content
  ///
  /// [content] - The note text to generate flashcards from
  /// [count] - Number of flashcards to generate (default: 10, max: 50)
  ///
  /// Returns a list of maps with 'question', 'answer', and 'difficulty' keys
  /// Throws [GeminiException] on failure
  Future<List<Map<String, String>>> generateFlashcards(
    String content, {
    int count = 10,
  }) async {
    // Validate input
    if (content.trim().isEmpty) {
      throw const GeminiException('Cannot generate flashcards from empty content');
    }

    // Enforce limits
    final requestedCount = count.clamp(1, AppConstants.maxFlashcardsPerNote);

    // Check minimum content length
    if (content.trim().length < 100) {
      throw const GeminiException(
        ErrorMessages.flashcardContentTooShort,
        'CONTENT_TOO_SHORT',
      );
    }

    // Truncate content if too long
    final truncatedContent = _truncateContent(content, _maxInputChars);

    try {
      // Build flashcard-specific prompt
      final prompt = _buildFlashcardsPrompt(truncatedContent, requestedCount);

      // Generate content using flashcard model (higher token limit)
      final response = await flashcardModel.generateContent([Content.text(prompt)]);

      // Parse and validate response
      final flashcards = _parseFlashcardsResponse(response.text);

      if (flashcards.isEmpty) {
        throw const GeminiException(
          ErrorMessages.noFlashcardsGenerated,
          'NO_FLASHCARDS',
        );
      }

      return flashcards;
    } on GenerativeAIException catch (e) {
      throw _handleGeminiError(e);
    } on GeminiException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[GeminiService] Flashcard generation error: $e');
      debugPrint('[GeminiService] Stack trace: $stackTrace');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('network') ||
          errorStr.contains('timeout')) {
        throw const GeminiException(
          'Network error. Please check your internet connection.',
          'NETWORK_ERROR',
        );
      }

      throw GeminiException('${ErrorMessages.flashcardGenerationFailed}: $e');
    }
  }

  /// Build prompt for flashcard generation
  String _buildFlashcardsPrompt(String content, int count) {
    return '''Generate exactly $count flashcards from the study material below.

OUTPUT FORMAT: Return ONLY a valid JSON array. Do not include any text, explanation, or markdown code blocks - just the raw JSON array starting with [ and ending with ].

Each flashcard object must have these exact keys:
- "question": the flashcard question (string)
- "answer": the flashcard answer, 1-3 sentences (string)
- "difficulty": one of "easy", "medium", or "hard" (string)

Example of correct output format:
[{"question":"What is X?","answer":"X is...","difficulty":"easy"},{"question":"How does Y work?","answer":"Y works by...","difficulty":"medium"}]

STUDY MATERIAL:
$content''';
  }

  /// Parse flashcards from Gemini response
  List<Map<String, String>> _parseFlashcardsResponse(String? responseText) {
    if (responseText == null || responseText.trim().isEmpty) {
      throw const GeminiException('Failed to generate flashcards - empty response');
    }

    debugPrint('[GeminiService] Raw response length: ${responseText.length}');
    debugPrint('[GeminiService] Raw response (first 500 chars): ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}');

    // Clean response
    String cleaned = responseText.trim();

    // Remove thinking content from Gemini 2.5/3 thinking models
    // Pattern 1: <thinking>...</thinking> tags
    cleaned = cleaned.replaceAll(RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false), '');
    // Pattern 2: **Thinking:** or similar markdown headers for thinking
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(?:Thinking|Analysis|Reasoning)[:\*]*\*\*[\s\S]*?(?=\[|$)', caseSensitive: false), '');
    // Pattern 3: Lines starting with "Thinking:" or similar
    cleaned = cleaned.replaceAll(RegExp(r'^(?:Thinking|Analysis|Reasoning):.*$', multiLine: true, caseSensitive: false), '');

    // Remove markdown code block markers (handles ```json, ```JSON, ``` variants)
    final codeBlockPattern = RegExp(r'```(?:json|JSON)?\s*\n?');
    final endCodeBlockPattern = RegExp(r'\n?```');
    cleaned = cleaned.replaceAll(codeBlockPattern, '');
    cleaned = cleaned.replaceAll(endCodeBlockPattern, '');
    cleaned = cleaned.trim();

    // Try to extract JSON array using regex (more robust)
    String? jsonString;

    // Pattern 1: Find JSON array with balanced brackets
    final jsonArrayPattern = RegExp(r'\[[\s\S]*\]');
    final match = jsonArrayPattern.firstMatch(cleaned);

    if (match != null) {
      jsonString = match.group(0);

      // Find the properly balanced JSON array
      if (jsonString != null) {
        int bracketCount = 0;
        int startIdx = -1;
        int endIdx = -1;

        for (int i = 0; i < jsonString.length; i++) {
          if (jsonString[i] == '[') {
            if (startIdx == -1) startIdx = i;
            bracketCount++;
          } else if (jsonString[i] == ']') {
            bracketCount--;
            if (bracketCount == 0) {
              endIdx = i;
              break;
            }
          }
        }

        if (startIdx != -1 && endIdx != -1) {
          jsonString = jsonString.substring(startIdx, endIdx + 1);
        }
      }
    }

    // Pattern 2: If no match, try finding by brackets in original cleaned string
    if (jsonString == null || jsonString.isEmpty) {
      final startIndex = cleaned.indexOf('[');
      final endIndex = cleaned.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonString = cleaned.substring(startIndex, endIndex + 1);
      }
    }

    // Pattern 3: Handle truncated responses (no closing ])
    // Try to salvage partial flashcards from incomplete JSON
    if (jsonString == null || jsonString.isEmpty) {
      final startIndex = cleaned.indexOf('[');
      if (startIndex != -1) {
        debugPrint('[GeminiService] Response appears truncated, attempting to salvage...');
        String partial = cleaned.substring(startIndex);

        // Find the last complete object (ends with })
        final lastCompleteObject = partial.lastIndexOf('}');
        if (lastCompleteObject > 0) {
          partial = partial.substring(0, lastCompleteObject + 1);

          // Remove any trailing comma and add closing bracket
          partial = partial.trimRight();
          if (partial.endsWith(',')) {
            partial = partial.substring(0, partial.length - 1);
          }
          partial = '$partial]';

          debugPrint('[GeminiService] Salvaged partial JSON: ${partial.length} chars');
          jsonString = partial;
        }
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      debugPrint('[GeminiService] Could not find JSON array in response');
      debugPrint('[GeminiService] Cleaned response: $cleaned');
      throw const GeminiException(
        'Failed to parse flashcards - no valid JSON array found. Please try again.',
      );
    }

    debugPrint('[GeminiService] Extracted JSON (first 300 chars): ${jsonString.substring(0, jsonString.length > 300 ? 300 : jsonString.length)}');

    // Try to fix common JSON issues before parsing
    jsonString = _fixCommonJsonIssues(jsonString);

    // Parse JSON
    try {
      final List<dynamic> parsed = json.decode(jsonString);

      if (parsed.isEmpty) {
        throw const GeminiException('AI returned empty flashcard list');
      }

      final flashcards = <Map<String, String>>[];

      for (int i = 0; i < parsed.length; i++) {
        final item = parsed[i];

        if (item is! Map) {
          debugPrint('[GeminiService] Skipping item $i - not a Map: ${item.runtimeType}');
          continue;
        }

        final question = item['question']?.toString().trim() ?? '';
        final answer = item['answer']?.toString().trim() ?? '';
        final difficulty = item['difficulty']?.toString().toLowerCase() ?? 'medium';

        if (question.isEmpty || answer.isEmpty) {
          debugPrint('[GeminiService] Skipping item $i - empty question or answer');
          continue;
        }

        // Validate difficulty
        final validDifficulty = [
          AppConstants.difficultyEasy,
          AppConstants.difficultyMedium,
          AppConstants.difficultyHard,
        ].contains(difficulty)
            ? difficulty
            : AppConstants.difficultyMedium;

        flashcards.add({
          'question': question,
          'answer': answer,
          'difficulty': validDifficulty,
        });
      }

      debugPrint('[GeminiService] Successfully parsed ${flashcards.length} flashcards');
      return flashcards;
    } on FormatException catch (e) {
      debugPrint('[GeminiService] JSON format error: $e');
      debugPrint('[GeminiService] Attempted to parse: $jsonString');

      // Try to provide more helpful error message
      if (jsonString.contains("'")) {
        throw const GeminiException(
          'Failed to parse flashcards - AI used invalid quotes. Please try again.',
        );
      }
      throw GeminiException('Failed to parse flashcards - invalid JSON format: ${e.message}');
    } catch (e) {
      debugPrint('[GeminiService] JSON parse error: $e');
      debugPrint('[GeminiService] Response was: $jsonString');
      throw GeminiException('Failed to parse flashcards: $e');
    }
  }

  /// Fix common JSON issues that LLMs produce
  String _fixCommonJsonIssues(String jsonStr) {
    String fixed = jsonStr;

    // Fix trailing commas before ] or }
    fixed = fixed.replaceAll(RegExp(r',\s*\]'), ']');
    fixed = fixed.replaceAll(RegExp(r',\s*\}'), '}');

    // Fix single quotes used instead of double quotes
    // This is tricky - only replace if it's clearly JSON structure
    if (fixed.contains("'question'") || fixed.contains("'answer'") || fixed.contains("'difficulty'")) {
      // Replace single-quoted keys
      fixed = fixed.replaceAllMapped(
        RegExp(r"'(question|answer|difficulty)'"),
        (m) => '"${m.group(1)}"',
      );
      // Replace single-quoted values (this is risky but needed for malformed JSON)
      fixed = fixed.replaceAllMapped(
        RegExp(r":\s*'([^']*)'"),
        (m) => ': "${m.group(1)}"',
      );
    }

    // Remove any newlines inside string values (can break JSON)
    // This is complex - for now just ensure the array is properly formatted
    fixed = fixed.trim();

    return fixed;
  }

  // ========== AUDIO TRANSCRIPTION ==========

  /// Transcribe audio file to text using Gemini
  ///
  /// [audioFile] - The audio file to transcribe (m4a, mp3, wav, etc.)
  ///
  /// Returns the transcribed text
  /// Throws [GeminiException] on failure
  Future<String> transcribeAudio(File audioFile) async {
    if (!await audioFile.exists()) {
      throw const GeminiException('Audio file not found');
    }

    try {
      debugPrint('[GeminiService] Transcribing audio: ${audioFile.path}');

      // Read audio file bytes
      final audioBytes = await audioFile.readAsBytes();
      debugPrint('[GeminiService] Audio file size: ${audioBytes.length} bytes');

      // Determine MIME type based on file extension
      final extension = audioFile.path.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'm4a':
        case 'aac':
          mimeType = 'audio/mp4';
          break;
        case 'mp3':
          mimeType = 'audio/mpeg';
          break;
        case 'wav':
          mimeType = 'audio/wav';
          break;
        case 'ogg':
          mimeType = 'audio/ogg';
          break;
        case 'flac':
          mimeType = 'audio/flac';
          break;
        default:
          mimeType = 'audio/mp4'; // Default to mp4 for m4a files
      }

      debugPrint('[GeminiService] Using MIME type: $mimeType');

      // Build transcription prompt
      const prompt = '''Transcribe the following audio recording accurately.

Instructions:
- Output ONLY the transcribed text, nothing else
- Preserve the speaker's words as accurately as possible
- Include punctuation where appropriate
- If the audio is unclear or inaudible, use [inaudible] marker
- If there are multiple speakers, don't add speaker labels unless clearly distinct
- Do not add any commentary, summary, or notes about the audio

Transcription:''';

      // Create content with audio data
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, audioBytes),
        ]),
      ]);

      final transcription = response.text;
      if (transcription == null || transcription.trim().isEmpty) {
        throw const GeminiException(
          'Failed to transcribe audio. The recording may be too quiet or unclear.',
        );
      }

      debugPrint('[GeminiService] Transcription complete: ${transcription.length} chars');
      return transcription.trim();
    } on GenerativeAIException catch (e) {
      debugPrint('[GeminiService] Gemini API error during transcription: ${e.message}');
      throw _handleGeminiError(e);
    } on GeminiException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[GeminiService] Transcription error: $e');
      debugPrint('[GeminiService] Stack trace: $stackTrace');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('network') ||
          errorStr.contains('timeout')) {
        throw const GeminiException(
          'Network error. Please check your internet connection.',
          'NETWORK_ERROR',
        );
      }

      throw GeminiException('Failed to transcribe audio: $e');
    }
  }

  /// Dispose of resources (call when no longer needed)
  void dispose() {
    _model = null;
    _flashcardModel = null;
  }
}
