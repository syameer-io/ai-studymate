/// Notes List Screen
///
/// Displays all user notes in a scrollable list.
/// Allows navigation to create note and note detail screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/loading_widget.dart';
import 'note_detail_screen.dart';
import 'create_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notes provider with current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notesProvider = context.read<NotesProvider>();
      notesProvider.initialize(authProvider.uid);
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<NotesProvider>().refresh();
  }

  void _navigateToCreateNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateNoteScreen()),
    );
  }

  void _navigateToNoteDetail(NoteModel note) {
    context.read<NotesProvider>().selectNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateNote,
        child: const Icon(Icons.add),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          // Show loading state
          if (notesProvider.isLoading && notesProvider.notes.isEmpty) {
            return const LoadingIndicator(message: 'Loading notes...');
          }

          // Show error state
          if (notesProvider.errorMessage != null && notesProvider.notes.isEmpty) {
            return _buildErrorState(notesProvider);
          }

          // Show empty state
          if (notesProvider.notes.isEmpty) {
            return _buildEmptyState();
          }

          // Show notes list
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notesProvider.notes.length,
              itemBuilder: (context, index) {
                final note = notesProvider.notes[index];
                return _NoteCard(
                  note: note,
                  onTap: () => _navigateToNoteDetail(note),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note by tapping the + button',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateNote,
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(NotesProvider notesProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load notes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              notesProvider.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                notesProvider.clearError();
                notesProvider.loadNotes();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Note card widget for list display
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with file type icon
              Row(
                children: [
                  // File type indicator
                  _buildFileTypeIcon(),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Content preview
              Text(
                note.contentPreview,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Bottom row: date and subject
              Row(
                children: [
                  // Date
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  // Subject tag
                  if (note.subject != null && note.subject!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.subject!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Word count
                  Text(
                    '${note.wordCount} words',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData icon;
    Color color;

    if (note.isImageNote) {
      icon = Icons.image_outlined;
      color = AppColors.info;
    } else if (note.isPdfNote) {
      icon = Icons.picture_as_pdf_outlined;
      color = AppColors.error;
    } else {
      icon = Icons.text_snippet_outlined;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
