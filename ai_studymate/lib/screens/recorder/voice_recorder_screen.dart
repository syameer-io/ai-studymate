/// Voice Recorder Screen
///
/// Allows users to:
/// - Record audio with visual feedback
/// - Get AI-powered transcription (via Gemini)
/// - Playback recorded audio
/// - Save as note with transcription

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../services/speech_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

/// View states for the recorder screen
enum RecorderViewState {
  idle,          // Ready to record
  recording,     // Currently recording
  paused,        // Recording paused
  transcribing,  // Transcribing audio with AI
  preview,       // Ready to save or re-record
  saving,        // Saving to Firebase
}

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final SpeechService _speechService = SpeechService();
  final GeminiService _geminiService = GeminiService();

  // Controllers
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  late AnimationController _pulseController;
  AudioPlayer? _audioPlayer;

  // State
  RecorderViewState _viewState = RecorderViewState.idle;
  String _transcription = '';
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _recordedFilePath;
  bool _isPlaying = false;
  String? _transcriptionError;

  // Timer for UI updates
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
    _setupAudioPlayerListeners();

    // Initialize NotesProvider with current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notesProvider = context.read<NotesProvider>();
      notesProvider.initialize(authProvider.uid);
    });
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer?.onPositionChanged.listen((position) {
      if (mounted) setState(() => _playbackPosition = position);
    });

    _audioPlayer?.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });

    _audioPlayer?.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _pulseController.dispose();
    _audioPlayer?.dispose();
    _durationTimer?.cancel();
    _speechService.cancelRecording();
    super.dispose();
  }

  // ========== RECORDING METHODS ==========

  Future<void> _startRecording() async {
    try {
      // Start recording audio
      await _speechService.startRecording();

      _startDurationTimer();
      _pulseController.repeat(reverse: true);

      setState(() {
        _viewState = RecorderViewState.recording;
        _transcription = '';
        _transcriptionError = null;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _speechService.pauseRecording();
      _stopDurationTimer();
      _pulseController.stop();

      setState(() {
        _viewState = RecorderViewState.paused;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _speechService.resumeRecording();

      _startDurationTimer();
      _pulseController.repeat(reverse: true);

      setState(() {
        _viewState = RecorderViewState.recording;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordedFilePath = await _speechService.stopRecording();
      _stopDurationTimer();
      _pulseController.stop();

      if (_recordedFilePath == null) {
        _showError('No recording found');
        setState(() {
          _viewState = RecorderViewState.idle;
        });
        return;
      }

      // Move to transcribing state
      setState(() {
        _viewState = RecorderViewState.transcribing;
      });

      // Transcribe using Gemini AI
      await _transcribeAudio();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _viewState = RecorderViewState.preview;
      });
    }
  }

  Future<void> _transcribeAudio() async {
    if (_recordedFilePath == null) return;

    try {
      final audioFile = File(_recordedFilePath!);
      final transcription = await _geminiService.transcribeAudio(audioFile);

      if (mounted) {
        setState(() {
          _transcription = transcription;
          _transcriptionError = null;
          _viewState = RecorderViewState.preview;
        });

        // Auto-generate title from first 8 words
        if (_titleController.text.isEmpty && _transcription.isNotEmpty) {
          final words = _transcription.trim().split(' ');
          final firstWords = words.take(8).join(' ');
          _titleController.text = firstWords.length > 50
              ? '${firstWords.substring(0, 50)}...'
              : firstWords;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _transcriptionError = e.toString();
          _viewState = RecorderViewState.preview;
        });
      }
    }
  }

  Future<void> _retryTranscription() async {
    setState(() {
      _viewState = RecorderViewState.transcribing;
      _transcriptionError = null;
    });
    await _transcribeAudio();
  }

  Future<void> _cancelRecording() async {
    try {
      await _speechService.cancelRecording();
      _stopDurationTimer();
      _pulseController.stop();
      await _stopPlayback();

      setState(() {
        _viewState = RecorderViewState.idle;
        _transcription = '';
        _transcriptionError = null;
        _recordingDuration = Duration.zero;
        _recordedFilePath = null;
        _titleController.clear();
        _subjectController.clear();
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ========== PLAYBACK METHODS ==========

  Future<void> _togglePlayback() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer?.pause();
      } else {
        await _audioPlayer?.play(DeviceFileSource(_recordedFilePath!));
      }

      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      _showError('Playback error: $e');
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await _audioPlayer?.seek(position);
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer?.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    }
  }

  // ========== SAVE METHOD ==========

  Future<void> _saveAsNote() async {
    if (_transcription.trim().isEmpty) {
      _showError(ErrorMessages.transcriptionEmpty);
      return;
    }

    if (_recordedFilePath == null) {
      _showError('No recording found');
      return;
    }

    // Get provider reference before async operation
    final notesProvider = context.read<NotesProvider>();

    // Stop playback if playing
    await _stopPlayback();

    setState(() {
      _viewState = RecorderViewState.saving;
    });

    final title = _titleController.text.trim().isEmpty
        ? 'Voice Note ${DateFormat('MMM d, h:mm a').format(DateTime.now())}'
        : _titleController.text.trim();

    final subject = _subjectController.text.trim().isEmpty
        ? null
        : _subjectController.text.trim();

    final success = await notesProvider.createNoteFromAudio(
      audioFile: File(_recordedFilePath!),
      transcription: _transcription.trim(),
      title: title,
      subject: subject,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SuccessMessages.voiceNoteSaved),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _viewState = RecorderViewState.preview;
        });
        _showError(notesProvider.errorMessage ?? ErrorMessages.noteSaveFailed);
      }
    }
  }

  // ========== TIMER HELPERS ==========

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });

        // Auto-stop at max duration
        if (_recordingDuration.inSeconds >= AppConstants.maxAudioDurationSeconds) {
          _stopRecording();
          _showError(ErrorMessages.maxRecordingDurationReached);
        }
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // ========== UI HELPERS ==========

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ========== BUILD METHODS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder'),
        actions: [
          if (_viewState == RecorderViewState.preview && _transcription.isNotEmpty)
            Consumer<NotesProvider>(
              builder: (context, notesProvider, _) {
                return TextButton(
                  onPressed: notesProvider.isSaving ? null : _saveAsNote,
                  child: notesProvider.isSaving
                      ? const SmallLoadingIndicator(size: 20)
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Recording visualization
              _buildRecordingVisualization(),

              const SizedBox(height: 16),

              // Transcription display
              _buildTranscriptionArea(),

              const SizedBox(height: 16),

              // Controls and form
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingVisualization() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated recording indicator
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final isRecording = _viewState == RecorderViewState.recording;
            return Container(
              width: 100 + (isRecording ? _pulseController.value * 16 : 0),
              height: 100 + (isRecording ? _pulseController.value * 16 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getVisualizationColor(),
              ),
              child: Icon(
                _getMainIcon(),
                size: 48,
                color: _getMainIconColor(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Duration display
        Text(
          _formatDuration(_viewState == RecorderViewState.preview
              ? _playbackPosition
              : _recordingDuration),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
        ),

        // Status text
        const SizedBox(height: 4),
        Text(
          _getStatusText(),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Color _getVisualizationColor() {
    switch (_viewState) {
      case RecorderViewState.idle:
        return AppColors.primary.withValues(alpha: 0.1);
      case RecorderViewState.recording:
        return AppColors.accent.withValues(alpha: 0.2 + _pulseController.value * 0.3);
      case RecorderViewState.paused:
        return AppColors.warning.withValues(alpha: 0.2);
      case RecorderViewState.transcribing:
        return AppColors.info.withValues(alpha: 0.2);
      case RecorderViewState.preview:
        return AppColors.success.withValues(alpha: 0.2);
      case RecorderViewState.saving:
        return AppColors.info.withValues(alpha: 0.2);
    }
  }

  IconData _getMainIcon() {
    switch (_viewState) {
      case RecorderViewState.idle:
        return Icons.mic_none;
      case RecorderViewState.recording:
        return Icons.mic;
      case RecorderViewState.paused:
        return Icons.pause;
      case RecorderViewState.transcribing:
        return Icons.auto_awesome;
      case RecorderViewState.preview:
        return _isPlaying ? Icons.pause : Icons.play_arrow;
      case RecorderViewState.saving:
        return Icons.cloud_upload;
    }
  }

  Color _getMainIconColor() {
    switch (_viewState) {
      case RecorderViewState.idle:
        return AppColors.primary;
      case RecorderViewState.recording:
        return AppColors.accent;
      case RecorderViewState.paused:
        return AppColors.warning;
      case RecorderViewState.transcribing:
        return AppColors.info;
      case RecorderViewState.preview:
        return AppColors.success;
      case RecorderViewState.saving:
        return AppColors.info;
    }
  }

  String _getStatusText() {
    switch (_viewState) {
      case RecorderViewState.idle:
        return 'Tap to start recording';
      case RecorderViewState.recording:
        return 'Recording... (max ${_formatDuration(const Duration(seconds: AppConstants.maxAudioDurationSeconds))})';
      case RecorderViewState.paused:
        return 'Recording paused';
      case RecorderViewState.transcribing:
        return 'Transcribing with AI...';
      case RecorderViewState.preview:
        if (_totalDuration.inSeconds > 0) {
          return '/ ${_formatDuration(_totalDuration)}';
        }
        return 'Ready to save';
      case RecorderViewState.saving:
        return 'Saving note...';
    }
  }

  Widget _buildTranscriptionArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transcription',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_viewState == RecorderViewState.transcribing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: _buildTranscriptionContent(),
            ),
          ),
          if (_transcription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_transcription.split(' ').where((w) => w.isNotEmpty).length} words',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionContent() {
    // Show transcription error with retry option
    if (_transcriptionError != null && _transcription.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            _transcriptionError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retryTranscription,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Transcription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      );
    }

    // Show loading state
    if (_viewState == RecorderViewState.transcribing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'AI is transcribing your recording...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Show placeholder
    if (_transcription.isEmpty) {
      return Center(
        child: Text(
          _viewState == RecorderViewState.idle
              ? 'Tap the microphone to start recording...'
              : _viewState == RecorderViewState.recording || _viewState == RecorderViewState.paused
                  ? 'Recording in progress...\nTranscription will appear when you stop.'
                  : 'No transcription available',
          style: TextStyle(color: AppColors.textLight),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show transcription
    return Text(
      _transcription,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Playback slider (only in preview mode)
        if (_viewState == RecorderViewState.preview && _recordedFilePath != null)
          _buildPlaybackSlider(),

        // Control buttons
        _buildControlPanel(),

        // Form fields (only in preview mode with transcription)
        if (_viewState == RecorderViewState.preview && _transcription.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFormFields(),
        ],
      ],
    );
  }

  Widget _buildPlaybackSlider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            _formatDuration(_playbackPosition),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Slider(
              value: _playbackPosition.inMilliseconds.toDouble(),
              min: 0,
              max: _totalDuration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: _seekTo,
              activeColor: AppColors.primary,
            ),
          ),
          Text(
            _formatDuration(_totalDuration),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel/Reset button
        if (_viewState != RecorderViewState.idle &&
            _viewState != RecorderViewState.saving &&
            _viewState != RecorderViewState.transcribing)
          _ControlButton(
            icon: Icons.close,
            label: 'Cancel',
            color: AppColors.error,
            onTap: _cancelRecording,
          ),

        // Main action button
        _buildMainButton(),

        // Stop/Done button (during recording)
        if (_viewState == RecorderViewState.recording ||
            _viewState == RecorderViewState.paused)
          _ControlButton(
            icon: Icons.stop,
            label: 'Done',
            color: AppColors.success,
            onTap: _stopRecording,
          ),
      ],
    );
  }

  Widget _buildMainButton() {
    switch (_viewState) {
      case RecorderViewState.idle:
        return _RecordButton(onTap: _startRecording);
      case RecorderViewState.recording:
        return _ControlButton(
          icon: Icons.pause,
          label: 'Pause',
          color: AppColors.warning,
          onTap: _pauseRecording,
          size: 72,
        );
      case RecorderViewState.paused:
        return _ControlButton(
          icon: Icons.fiber_manual_record,
          label: 'Resume',
          color: AppColors.accent,
          onTap: _resumeRecording,
          size: 72,
        );
      case RecorderViewState.transcribing:
        return const SizedBox(
          width: 72,
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        );
      case RecorderViewState.preview:
        return _ControlButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          label: _isPlaying ? 'Pause' : 'Play',
          color: AppColors.primary,
          onTap: _togglePlayback,
          size: 72,
        );
      case RecorderViewState.saving:
        return const SizedBox(
          width: 72,
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        );
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _titleController,
          labelText: 'Title',
          hintText: 'Enter note title',
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _subjectController,
          labelText: 'Subject (optional)',
          hintText: 'e.g., Math, Physics, History',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Consumer<NotesProvider>(
          builder: (context, notesProvider, _) {
            return LoadingButton(
              isLoading: notesProvider.isSaving || _viewState == RecorderViewState.saving,
              onPressed: _saveAsNote,
              label: 'Save as Note',
              icon: Icons.save,
            );
          },
        ),
      ],
    );
  }
}

// ========== HELPER WIDGETS ==========

/// Large record button
class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RecordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Control button with icon and label
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
