/// Study Screen
///
/// Interactive flashcard study session with swipe gestures.
/// Uses flutter_card_swiper for swipe-based card navigation.
/// Tracks progress and shows results at the end.

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../utils/constants.dart';

class StudyScreen extends StatefulWidget {
  /// Optional: Filter to specific note's flashcards
  final String? noteId;

  /// Optional: Filter by difficulty
  final String? difficulty;

  /// Whether to only show cards due for review
  final bool dueOnly;

  const StudyScreen({
    super.key,
    this.noteId,
    this.difficulty,
    this.dueOnly = false,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  // Track which cards are flipped
  final Set<int> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final provider = context.read<FlashcardProvider>();
    provider.startStudySession(
      noteId: widget.noteId,
      difficulty: widget.difficulty,
      dueOnly: widget.dueOnly,
      shuffled: true,
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    final provider = context.read<FlashcardProvider>();

    // Record answer based on swipe direction
    final wasCorrect = direction == CardSwiperDirection.right;
    await provider.recordAnswer(wasCorrect);

    // Reset flip state for next card
    _flippedCards.remove(previousIndex);
  }

  void _onCardTap(int index) {
    setState(() {
      if (_flippedCards.contains(index)) {
        _flippedCards.remove(index);
      } else {
        _flippedCards.add(index);
      }
    });
  }

  void _swipeLeft() {
    _swiperController.swipe(CardSwiperDirection.left);
  }

  void _swipeRight() {
    _swiperController.swipe(CardSwiperDirection.right);
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<FlashcardProvider>();

    if (provider.isStudySessionActive && !provider.isStudySessionComplete) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Study Session?'),
          content: const Text(
            'Your progress will be saved, but you\'ll exit the current session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Studying'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        provider.endStudySession();
        return true;
      }
      return false;
    }

    provider.endStudySession();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Mode'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            // Progress indicator
            Consumer<FlashcardProvider>(
              builder: (context, provider, _) {
                if (provider.studyDeck.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      '${provider.currentCardIndex + 1} / ${provider.studyDeckSize}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<FlashcardProvider>(
          builder: (context, provider, _) {
            if (provider.studyDeck.isEmpty) {
              return _buildEmptyState();
            }

            if (provider.isStudySessionComplete) {
              return _buildResultsScreen(provider);
            }

            return Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: provider.studyProgress,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

                // Card swiper
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CardSwiper(
                      controller: _swiperController,
                      cardsCount: provider.studyDeck.length,
                      onSwipe: (prev, curr, dir) {
                        _onSwipe(prev, curr, dir);
                        return true;
                      },
                      numberOfCardsDisplayed:
                          provider.studyDeck.length.clamp(1, 3),
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 25,
                      ),
                      allowedSwipeDirection: AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                      ),
                      cardBuilder: (context, index, horizontalOffset, verticalOffset) {
                        return _StudyCard(
                          flashcard: provider.studyDeck[index],
                          isFlipped: _flippedCards.contains(index),
                          onTap: () => _onCardTap(index),
                          horizontalOffset: horizontalOffset.toDouble(),
                        );
                      },
                    ),
                  ),
                ),

                // Control buttons
                _buildControlButtons(),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Don't know button
          _ControlButton(
            icon: Icons.close,
            label: "Don't Know",
            color: AppColors.error,
            onTap: _swipeLeft,
          ),

          // Flip button
          Consumer<FlashcardProvider>(
            builder: (context, provider, _) {
              if (provider.currentCardIndex >= provider.studyDeck.length) {
                return const SizedBox.shrink();
              }
              return _ControlButton(
                icon: Icons.flip,
                label: 'Flip',
                color: AppColors.secondary,
                onTap: () => _onCardTap(provider.currentCardIndex),
                isSmall: true,
              );
            },
          ),

          // Know it button
          _ControlButton(
            icon: Icons.check,
            label: 'Know It',
            color: AppColors.success,
            onTap: _swipeRight,
          ),
        ],
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
              Icons.quiz_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No flashcards to study',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.dueOnly
                  ? 'No cards are due for review right now!'
                  : 'Create some flashcards first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(FlashcardProvider provider) {
    final total = provider.correctCount + provider.incorrectCount;
    final accuracy = provider.studySessionAccuracy;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy or celebration
            Icon(
              accuracy >= 0.8
                  ? Icons.emoji_events
                  : accuracy >= 0.5
                      ? Icons.thumb_up_alt
                      : Icons.school,
              size: 80,
              color: accuracy >= 0.8
                  ? Colors.amber
                  : accuracy >= 0.5
                      ? AppColors.success
                      : AppColors.primary,
            ),
            const SizedBox(height: 24),

            Text(
              accuracy >= 0.8
                  ? 'Excellent!'
                  : accuracy >= 0.5
                      ? 'Good job!'
                      : 'Keep practicing!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              SuccessMessages.studySessionComplete,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Results card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Accuracy circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: accuracy,
                            strokeWidth: 10,
                            backgroundColor: AppColors.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accuracy >= 0.8
                                  ? AppColors.success
                                  : accuracy >= 0.5
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                          Text(
                            '${(accuracy * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultStat(
                          label: 'Correct',
                          value: provider.correctCount.toString(),
                          color: AppColors.success,
                          icon: Icons.check_circle,
                        ),
                        _ResultStat(
                          label: 'Incorrect',
                          value: provider.incorrectCount.toString(),
                          color: AppColors.error,
                          icon: Icons.cancel,
                        ),
                        _ResultStat(
                          label: 'Total',
                          value: total.toString(),
                          color: AppColors.primary,
                          icon: Icons.quiz,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.endStudySession();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _flippedCards.clear();
                      _startSession();
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Study Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Study card widget with flip animation
class _StudyCard extends StatelessWidget {
  final FlashcardModel flashcard;
  final bool isFlipped;
  final VoidCallback onTap;
  final double horizontalOffset;

  const _StudyCard({
    required this.flashcard,
    required this.isFlipped,
    required this.onTap,
    required this.horizontalOffset,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate color based on swipe direction
    Color? overlayColor;
    if (horizontalOffset > 20) {
      overlayColor = AppColors.success.withValues(alpha: (horizontalOffset / 200).clamp(0, 0.3));
    } else if (horizontalOffset < -20) {
      overlayColor = AppColors.error.withValues(alpha: (-horizontalOffset / 200).clamp(0, 0.3));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Container(
          key: ValueKey(isFlipped),
          decoration: BoxDecoration(
            color: overlayColor != null
                ? Color.alphaBlend(overlayColor, Colors.white)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Card type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isFlipped
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFlipped
                                ? Icons.lightbulb_outline
                                : Icons.help_outline,
                            size: 16,
                            color: isFlipped
                                ? AppColors.success
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFlipped ? 'ANSWER' : 'QUESTION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isFlipped
                                  ? AppColors.success
                                  : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Content
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            isFlipped ? flashcard.answer : flashcard.question,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Difficulty indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: flashcard.difficultyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        flashcard.difficultyDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: flashcard.difficultyColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tap hint
                    if (!isFlipped)
                      Text(
                        'Tap to reveal answer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                  ],
                ),
              ),

              // Swipe indicators
              if (horizontalOffset > 20)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              if (horizontalOffset < -20)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 50 : 64,
            height: isSmall ? 50 : 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmall ? 24 : 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result stat widget
class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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
