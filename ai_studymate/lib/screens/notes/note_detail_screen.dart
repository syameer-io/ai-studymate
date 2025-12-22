/// Note Detail Screen
///
/// Displays full content of a single note.
/// Allows editing and deletion.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme_config.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../utils/constants.dart';
import '../flashcards/flashcards_list_screen.dart';
import '../flashcards/study_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final note = notesProvider.selectedNote;

        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Note')),
            body: const Center(child: Text('Note not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(note.displayTitle),
            actions: [
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context, note),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata card
                _buildMetadataCard(context, note),
                const SizedBox(height: 16),

                // Image preview (if image note)
                if (note.isImageNote && note.fileUrl != null)
                  _buildImagePreview(context, note),

                // PDF indicator (if PDF note)
                if (note.isPdfNote && note.fileUrl != null)
                  _buildPdfIndicator(context, note),

                // Audio player (if audio note)
                if (note.isAudioNote && note.fileUrl != null)
                  _AudioPlayerWidget(audioUrl: note.fileUrl!),

                // Content section
                _buildContentSection(context, note),

                const SizedBox(height: 16),

                // AI Summary section (always show - with generate option)
                _buildAISummarySection(context, note, notesProvider),

                const SizedBox(height: 16),

                // Flashcards section
                _buildFlashcardsSection(context, note),

                // Extra padding at bottom for better scrolling
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataCard(BuildContext context, NoteModel note) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              note.displayTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Metadata row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // File type
                _buildMetadataChip(
                  icon: _getFileTypeIcon(note),
                  label: _getFileTypeLabel(note),
                  color: _getFileTypeColor(note),
                ),
                // Date
                _buildMetadataChip(
                  icon: Icons.calendar_today_outlined,
                  label: note.formattedDateTime,
                  color: AppColors.textSecondary,
                ),
                // Word count
                _buildMetadataChip(
                  icon: Icons.text_fields,
                  label: '${note.wordCount} words',
                  color: AppColors.textSecondary,
                ),
                // Subject
                if (note.subject != null && note.subject!.isNotEmpty)
                  _buildMetadataChip(
                    icon: Icons.label_outline,
                    label: note.subject!,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getFileTypeIcon(NoteModel note) {
    if (note.isImageNote) return Icons.image_outlined;
    if (note.isPdfNote) return Icons.picture_as_pdf_outlined;
    if (note.isAudioNote) return Icons.mic_outlined;
    return Icons.text_snippet_outlined;
  }

  String _getFileTypeLabel(NoteModel note) {
    if (note.isImageNote) return 'Image Note';
    if (note.isPdfNote) return 'PDF Note';
    if (note.isAudioNote) return 'Voice Note';
    return 'Text Note';
  }

  Color _getFileTypeColor(NoteModel note) {
    if (note.isImageNote) return AppColors.info;
    if (note.isPdfNote) return AppColors.error;
    if (note.isAudioNote) return AppColors.accent;
    return AppColors.primary;
  }

  Widget _buildImagePreview(BuildContext context, NoteModel note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source Image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: note.fileUrl!,
            placeholder: (context, url) => Container(
              height: 200,
              color: AppColors.surface,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text('Failed to load image',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPdfIndicator(BuildContext context, NoteModel note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source File',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.error.withValues(alpha: 0.1),
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 32),
            title: const Text('PDF Document'),
            subtitle: const Text('Text extracted from this PDF'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, NoteModel note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              note.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build AI Summary section with generate/regenerate functionality
  Widget _buildAISummarySection(
    BuildContext context,
    NoteModel note,
    NotesProvider notesProvider,
  ) {
    final hasSummary = note.summary != null && note.summary!.isNotEmpty;
    final isGenerating = notesProvider.isGeneratingSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with action button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
            // Generate/Regenerate button (only show when not generating)
            if (!isGenerating)
              TextButton.icon(
                onPressed: () => _generateSummary(context, note.id),
                icon: Icon(
                  hasSummary ? Icons.refresh : Icons.auto_awesome,
                  size: 18,
                ),
                label: Text(hasSummary ? 'Regenerate' : 'Generate'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Summary content based on state
        if (isGenerating)
          _buildGeneratingPlaceholder(context)
        else if (hasSummary)
          _buildSummaryCard(context, note.summary!)
        else
          _buildEmptySummaryCard(context, note.id),
      ],
    );
  }

  /// Build loading placeholder during generation
  Widget _buildGeneratingPlaceholder(BuildContext context) {
    return Card(
      color: AppColors.secondary.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating AI summary...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build card showing the summary
  Widget _buildSummaryCard(BuildContext context, String summary) {
    return Card(
      color: AppColors.secondary.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          summary,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Build empty state card with generate button
  Widget _buildEmptySummaryCard(BuildContext context, String noteId) {
    return Card(
      color: AppColors.surfaceVariant,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.summarize_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No summary yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate an AI-powered summary to quickly review key concepts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _generateSummary(context, noteId),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger summary generation
  Future<void> _generateSummary(BuildContext context, String noteId) async {
    final notesProvider = context.read<NotesProvider>();
    final success = await notesProvider.generateNoteSummary(noteId);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Summary generated successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notesProvider.errorMessage ?? 'Failed to generate summary'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _generateSummary(context, noteId),
            ),
          ),
        );
      }
    }
  }

  /// Build Flashcards section with generate and study options
  Widget _buildFlashcardsSection(BuildContext context, NoteModel note) {
    return Consumer<FlashcardProvider>(
      builder: (context, flashcardProvider, _) {
        final noteFlashcards = flashcardProvider.getFlashcardsForNote(note.id);
        final isGenerating = flashcardProvider.isGenerating;
        final hasFlashcards = noteFlashcards.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Flashcards',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                    ),
                    if (hasFlashcards) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${noteFlashcards.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Generate/Add more button (only show when not generating)
                if (!isGenerating)
                  TextButton.icon(
                    onPressed: () => _generateFlashcards(context, note),
                    icon: Icon(
                      hasFlashcards ? Icons.add : Icons.auto_awesome,
                      size: 18,
                    ),
                    label: Text(hasFlashcards ? 'Add More' : 'Generate'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Content based on state
            if (isGenerating)
              _buildGeneratingFlashcardsPlaceholder(context)
            else if (hasFlashcards)
              _buildFlashcardsPreviewCard(context, note, noteFlashcards)
            else
              _buildEmptyFlashcardsCard(context, note),
          ],
        );
      },
    );
  }

  /// Build loading placeholder during flashcard generation
  Widget _buildGeneratingFlashcardsPlaceholder(BuildContext context) {
    return Card(
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating flashcards with AI...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creating study cards from your notes',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build card showing flashcard preview with actions
  Widget _buildFlashcardsPreviewCard(
    BuildContext context,
    NoteModel note,
    List flashcards,
  ) {
    // Show first 3 flashcards as preview
    final previewCards = flashcards.take(3).toList();

    return Card(
      child: Column(
        children: [
          // Preview of flashcards
          ...previewCards.map((fc) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fc.difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                    color: fc.difficultyColor,
                  ),
                ),
                title: Text(
                  fc.questionPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  fc.difficultyDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: fc.difficultyColor,
                  ),
                ),
              )),

          if (flashcards.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '+ ${flashcards.length - 3} more flashcards',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashcardsListScreen(
                            filterNoteId: note.id,
                            noteTitle: note.displayTitle,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list, size: 18),
                    label: const Text('View All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyScreen(noteId: note.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Study'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state card with generate button
  Widget _buildEmptyFlashcardsCard(BuildContext context, NoteModel note) {
    return Card(
      color: AppColors.surfaceVariant,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No flashcards yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate AI-powered flashcards to study this note effectively',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _generateFlashcards(context, note),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Flashcards'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger flashcard generation
  Future<void> _generateFlashcards(BuildContext context, NoteModel note) async {
    // Check content length
    if (note.content.trim().length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note content is too short to generate flashcards. Add more content first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Get auth provider to get user ID
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to generate flashcards'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Initialize flashcard provider with user ID
    final flashcardProvider = context.read<FlashcardProvider>();
    flashcardProvider.initialize(authProvider.uid);

    final success = await flashcardProvider.generateFlashcardsFromNote(
      noteId: note.id,
      noteContent: note.content,
      count: 10,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(SuccessMessages.flashcardsGenerated),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(flashcardProvider.errorMessage ?? ErrorMessages.flashcardGenerationFailed),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _generateFlashcards(context, note),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.displayTitle}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final notesProvider = context.read<NotesProvider>();
              final success = await notesProvider.deleteNote(note.id);

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(SuccessMessages.noteDeleted),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(notesProvider.errorMessage ?? ErrorMessages.noteDeleteFailed),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful audio player widget for audio notes
class _AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const _AudioPlayerWidget({required this.audioUrl});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }
    });

    // Listen to player completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    // Set the audio source
    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.audioPlaybackFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _seekTo(double value) async {
    await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Recording',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.accent.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Play/Pause button
                    IconButton(
                      onPressed: _isLoading ? null : _togglePlayPause,
                      icon: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 48,
                              color: AppColors.accent,
                            ),
                      iconSize: 48,
                    ),
                    const SizedBox(width: 12),
                    // Progress info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Recording',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to ${_isPlaying ? 'pause' : 'play'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Duration
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    min: 0,
                    max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: _isLoading ? null : _seekTo,
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
