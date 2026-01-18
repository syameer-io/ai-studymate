/// Flashcards List Screen
///
/// Displays all user's flashcards with filtering and navigation to study mode.
/// Supports filtering by difficulty and source note.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'create_flashcard_screen.dart';
import 'study_screen.dart';

class FlashcardsListScreen extends StatefulWidget {
  /// Optional: pre-filter to a specific note
  final String? filterNoteId;

  /// Optional: display note title when filtered
  final String? noteTitle;

  const FlashcardsListScreen({
    super.key,
    this.filterNoteId,
    this.noteTitle,
  });

  @override
  State<FlashcardsListScreen> createState() => _FlashcardsListScreenState();
}

class _FlashcardsListScreenState extends State<FlashcardsListScreen> {
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    // Initialize provider after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    final authProvider = context.read<AuthProvider>();
    final flashcardProvider = context.read<FlashcardProvider>();

    if (authProvider.isAuthenticated) {
      flashcardProvider.initialize(authProvider.uid);

      // Apply note filter if provided
      if (widget.filterNoteId != null) {
        flashcardProvider.filterByNote(widget.filterNoteId);
      }
    }
  }

  void _onDifficultyFilterChanged(String? difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    context.read<FlashcardProvider>().filterByDifficulty(difficulty);
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFlashcardScreen(
          preselectedNoteId: widget.filterNoteId,
        ),
      ),
    );
  }

  void _navigateToStudy() {
    final provider = context.read<FlashcardProvider>();

    if (provider.displayFlashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No flashcards available to study'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          noteId: widget.filterNoteId,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
  }

  void _navigateToEdit(FlashcardModel flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFlashcardScreen(
          flashcard: flashcard,
        ),
      ),
    );
  }

  Future<void> _deleteFlashcard(FlashcardModel flashcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text(
          'Are you sure you want to delete this flashcard? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<FlashcardProvider>().deleteFlashcard(flashcard.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? SuccessMessages.flashcardDeleted
                  : ErrorMessages.flashcardDeleteFailed,
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteTitle ?? 'Flashcards'),
        actions: [
          // Study button
          Consumer<FlashcardProvider>(
            builder: (context, provider, _) {
              final hasCards = provider.displayFlashcards.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: 'Start Study Session',
                onPressed: hasCards ? _navigateToStudy : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterBar(),

          // Stats card
          _buildStatsCard(),

          // Flashcard list
          Expanded(
            child: Consumer<FlashcardProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return _buildErrorState(provider.errorMessage!);
                }

                if (provider.displayFlashcards.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: provider.displayFlashcards.length,
                    itemBuilder: (context, index) {
                      return _FlashcardCard(
                        flashcard: provider.displayFlashcards[index],
                        onEdit: () =>
                            _navigateToEdit(provider.displayFlashcards[index]),
                        onDelete: () =>
                            _deleteFlashcard(provider.displayFlashcards[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        tooltip: 'Create Flashcard',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: _selectedDifficulty == null,
              onSelected: () => _onDifficultyFilterChanged(null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Easy',
              isSelected: _selectedDifficulty == AppConstants.difficultyEasy,
              onSelected: () =>
                  _onDifficultyFilterChanged(AppConstants.difficultyEasy),
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Medium',
              isSelected: _selectedDifficulty == AppConstants.difficultyMedium,
              onSelected: () =>
                  _onDifficultyFilterChanged(AppConstants.difficultyMedium),
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Hard',
              isSelected: _selectedDifficulty == AppConstants.difficultyHard,
              onSelected: () =>
                  _onDifficultyFilterChanged(AppConstants.difficultyHard),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        if (provider.flashcards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: provider.displayCount.toString(),
                    icon: Icons.quiz_outlined,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Accuracy',
                    value: '${(provider.overallAccuracy * 100).toStringAsFixed(0)}%',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Due',
                    value: provider.dueCount.toString(),
                    icon: Icons.schedule,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              Icons.quiz_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              widget.filterNoteId != null
                  ? 'No flashcards for this note'
                  : 'No flashcards yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.filterNoteId != null
                  ? 'Generate flashcards from your note or create them manually.'
                  : 'Create flashcards to start studying!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Flashcard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<FlashcardProvider>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Flashcard card widget
class _FlashcardCard extends StatefulWidget {
  final FlashcardModel flashcard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashcardCard({
    required this.flashcard,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<_FlashcardCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Question text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpanded
                              ? widget.flashcard.question
                              : widget.flashcard.questionPreview,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Metadata row
                        Row(
                          children: [
                            // Difficulty chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.flashcard.difficultyColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.flashcard.difficultyDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: widget.flashcard.difficultyColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stats
                            if (widget.flashcard.timesReviewed > 0) ...[
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.flashcard.accuracyPercent,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Last reviewed
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.flashcard.formattedLastReviewed,
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

                  // Expand/collapse icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textLight,
                  ),
                ],
              ),

              // Expanded content - Answer
              if (_isExpanded) ...[
                const Divider(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectableText(
                        widget.flashcard.answer,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
