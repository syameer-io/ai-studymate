/// Create/Edit Flashcard Screen
///
/// Allows users to manually create or edit flashcards.
/// Supports linking to notes and difficulty selection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../utils/constants.dart';

class CreateFlashcardScreen extends StatefulWidget {
  /// Existing flashcard for editing (null for create mode)
  final FlashcardModel? flashcard;

  /// Optional: pre-selected note ID
  final String? preselectedNoteId;

  const CreateFlashcardScreen({
    super.key,
    this.flashcard,
    this.preselectedNoteId,
  });

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  String _selectedDifficulty = AppConstants.difficultyMedium;
  String? _selectedNoteId;

  bool get _isEditMode => widget.flashcard != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // Populate fields for editing
      _questionController.text = widget.flashcard!.question;
      _answerController.text = widget.flashcard!.answer;
      _selectedDifficulty = widget.flashcard!.difficulty;
      _selectedNoteId = widget.flashcard!.noteId;
    } else if (widget.preselectedNoteId != null) {
      _selectedNoteId = widget.preselectedNoteId;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FlashcardProvider>();

    bool success;

    if (_isEditMode) {
      // Update existing flashcard
      final updated = widget.flashcard!.copyWith(
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        difficulty: _selectedDifficulty,
        noteId: _selectedNoteId,
      );
      success = await provider.updateFlashcard(updated);
    } else {
      // Create new flashcard
      success = await provider.createFlashcard(
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        difficulty: _selectedDifficulty,
        noteId: _selectedNoteId,
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? SuccessMessages.flashcardSaved
                  : SuccessMessages.flashcardCreated,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? ErrorMessages.flashcardSaveFailed),
            backgroundColor: AppColors.error,
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
        title: Text(_isEditMode ? 'Edit Flashcard' : 'Create Flashcard'),
        actions: [
          Consumer<FlashcardProvider>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isSaving ? null : _handleSave,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question field
              Text(
                'Question',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter your question...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 48),
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ErrorMessages.questionRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Answer field
              Text(
                'Answer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _answerController,
                maxLines: 6,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter the answer...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 96),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.success,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ErrorMessages.answerRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Difficulty selector
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DifficultyButton(
                      label: 'Easy',
                      difficulty: AppConstants.difficultyEasy,
                      isSelected:
                          _selectedDifficulty == AppConstants.difficultyEasy,
                      color: AppColors.success,
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = AppConstants.difficultyEasy;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DifficultyButton(
                      label: 'Medium',
                      difficulty: AppConstants.difficultyMedium,
                      isSelected:
                          _selectedDifficulty == AppConstants.difficultyMedium,
                      color: AppColors.warning,
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = AppConstants.difficultyMedium;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DifficultyButton(
                      label: 'Hard',
                      difficulty: AppConstants.difficultyHard,
                      isSelected:
                          _selectedDifficulty == AppConstants.difficultyHard,
                      color: AppColors.error,
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = AppConstants.difficultyHard;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 20,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for good flashcards',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TipItem(text: 'Keep questions clear and specific'),
                    _TipItem(text: 'Keep answers concise (2-3 sentences)'),
                    _TipItem(text: 'Test understanding, not just memorization'),
                    _TipItem(text: 'Use "Easy" for facts, "Hard" for application'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Difficulty selection button
class _DifficultyButton extends StatelessWidget {
  final String label;
  final String difficulty;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.difficulty,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppColors.textLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              difficulty == AppConstants.difficultyEasy
                  ? Icons.sentiment_satisfied_alt
                  : difficulty == AppConstants.difficultyMedium
                      ? Icons.sentiment_neutral
                      : Icons.sentiment_very_dissatisfied,
              color: isSelected ? color : AppColors.textLight,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tip item widget
class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
