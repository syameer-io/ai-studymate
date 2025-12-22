/// Speech Service
///
/// Handles audio recording and speech-to-text transcription.
/// Uses singleton pattern with lazy initialization.
///
/// Usage:
///   final speechService = SpeechService();
///   await speechService.startRecording();
///   await speechService.startListening(onResult: (text, isFinal) => print(text));

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../utils/constants.dart';

/// Custom exception for speech/recording errors
class SpeechException implements Exception {
  final String message;
  final String? code;

  const SpeechException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Recording state enum
enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}

class SpeechService {
  // Singleton pattern
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // Dependencies (lazy initialization)
  AudioRecorder? _recorder;
  SpeechToText? _speechToText;

  // State
  RecordingState _recordingState = RecordingState.idle;
  bool _isListening = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  // Getters
  RecordingState get recordingState => _recordingState;
  bool get isRecording => _recordingState == RecordingState.recording;
  bool get isPaused => _recordingState == RecordingState.paused;
  bool get isStopped => _recordingState == RecordingState.stopped;
  bool get isIdle => _recordingState == RecordingState.idle;
  bool get isListening => _isListening;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Get or create audio recorder instance
  AudioRecorder get recorder {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  /// Get or create speech-to-text instance
  SpeechToText get speechToText {
    _speechToText ??= SpeechToText();
    return _speechToText!;
  }

  // ========== INITIALIZATION ==========

  /// Initialize speech-to-text engine
  /// Call once at app startup or before first use
  Future<bool> initializeSpeech() async {
    try {
      final available = await speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      return available;
    } catch (e) {
      debugPrint('[SpeechService] Failed to initialize speech: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isSpeechAvailable() async {
    try {
      if (!speechToText.isAvailable) {
        return await initializeSpeech();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    try {
      return await recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  // ========== RECORDING METHODS ==========

  /// Start audio recording
  /// [filePath] - Optional custom path, otherwise generates unique path
  Future<void> startRecording({String? filePath}) async {
    try {
      if (_recordingState == RecordingState.recording) {
        throw const SpeechException('Already recording');
      }

      // Check permission
      if (!await recorder.hasPermission()) {
        throw SpeechException(
          ErrorMessages.speechPermissionDenied,
          'PERMISSION_DENIED',
        );
      }

      // Generate file path if not provided
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recordingsDir = Directory('${directory.path}/recordings');

      // Ensure directory exists
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      _currentRecordingPath = filePath ?? '${recordingsDir.path}/audio_$timestamp.m4a';

      // Start recording with AAC configuration (as per user preference)
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,  // AAC/M4A format
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _recordingState = RecordingState.recording;
      _recordingDuration = Duration.zero;
      _startDurationTimer();
    } on SpeechException {
      rethrow;
    } catch (e) {
      throw SpeechException('${ErrorMessages.recordingFailed}: $e');
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_recordingState != RecordingState.recording) {
      throw const SpeechException('Not currently recording');
    }

    try {
      await recorder.pause();
      _recordingState = RecordingState.paused;
      _stopDurationTimer();
    } catch (e) {
      throw SpeechException('Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_recordingState != RecordingState.paused) {
      throw const SpeechException('Recording not paused');
    }

    try {
      await recorder.resume();
      _recordingState = RecordingState.recording;
      _startDurationTimer();
    } catch (e) {
      throw SpeechException('Failed to resume recording: $e');
    }
  }

  /// Stop recording and return file path
  Future<String?> stopRecording() async {
    if (_recordingState != RecordingState.recording &&
        _recordingState != RecordingState.paused) {
      return null;
    }

    try {
      final path = await recorder.stop();
      _recordingState = RecordingState.stopped;
      _stopDurationTimer();
      return path ?? _currentRecordingPath;
    } catch (e) {
      throw SpeechException('${ErrorMessages.recordingStopFailed}: $e');
    }
  }

  /// Cancel recording and delete file
  Future<void> cancelRecording() async {
    try {
      await recorder.stop();
      _recordingState = RecordingState.idle;
      _stopDurationTimer();

      // Delete the partial recording
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
    } catch (e) {
      debugPrint('[SpeechService] Cancel recording error: $e');
      // Reset state even on error
      _recordingState = RecordingState.idle;
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
    }
  }

  // ========== SPEECH-TO-TEXT METHODS ==========

  /// Start listening for speech and transcribing
  /// [onResult] - Callback with transcribed text (text, isFinal)
  /// [localeId] - Language locale (default: en_US)
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (_isListening) {
      return; // Already listening, ignore
    }

    try {
      if (!await isSpeechAvailable()) {
        throw SpeechException(
          ErrorMessages.speechNotAvailable,
          'NOT_AVAILABLE',
        );
      }

      _isListening = true;

      await speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(minutes: 5), // Max listen duration
        pauseFor: const Duration(seconds: 3),  // Pause detection
        localeId: localeId ?? 'en_US',
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      if (e is SpeechException) rethrow;
      throw SpeechException('Failed to start speech recognition: $e');
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    try {
      await speechToText.stop();
      _isListening = false;
    } catch (e) {
      _isListening = false;
      debugPrint('[SpeechService] Stop listening error: $e');
    }
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      await isSpeechAvailable();
      return await speechToText.locales();
    } catch (e) {
      return [];
    }
  }

  // ========== AUDIO FILE MANAGEMENT ==========

  /// Delete an audio file
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[SpeechService] Delete file error: $e');
    }
  }

  /// Get audio file size in bytes
  Future<int> getAudioFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if recording exceeds max duration
  bool isMaxDurationReached() {
    return _recordingDuration.inSeconds >= AppConstants.maxAudioDurationSeconds;
  }

  // ========== PRIVATE HELPERS ==========

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration += const Duration(seconds: 1);

      // Auto-stop at max duration
      if (isMaxDurationReached()) {
        stopRecording();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint('[SpeechService] Speech error: ${error.errorMsg}');
    _isListening = false;
  }

  void _handleSpeechStatus(String status) {
    debugPrint('[SpeechService] Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  // ========== RESOURCE MANAGEMENT ==========

  /// Reset state without disposing resources
  void reset() {
    _recordingState = RecordingState.idle;
    _stopDurationTimer();
    _recordingDuration = Duration.zero;
    _currentRecordingPath = null;
    _isListening = false;
  }

  /// Dispose of all resources
  /// Call when service is no longer needed
  void dispose() {
    _recorder?.dispose();
    _recorder = null;
    speechToText.stop();
    _stopDurationTimer();
    _recordingState = RecordingState.idle;
    _isListening = false;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
  }
}
