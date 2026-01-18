/// Countdown Widget
///
/// Reusable countdown display component for exams.
/// Shows days remaining with color-coded urgency.

import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

/// Size variants for countdown widget
enum CountdownSize { small, medium, large }

class CountdownWidget extends StatelessWidget {
  /// Days remaining until exam (can be negative for past dates)
  final int daysRemaining;

  /// Whether the exam is completed
  final bool isCompleted;

  /// Size variant of the widget
  final CountdownSize size;

  /// Optional custom color override
  final Color? customColor;

  const CountdownWidget({
    super.key,
    required this.daysRemaining,
    this.isCompleted = false,
    this.size = CountdownSize.medium,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: _getBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Completed icon or day number
          if (isCompleted)
            Icon(
              Icons.check_circle,
              size: _getIconSize(),
              color: AppColors.success,
            )
          else
            Text(
              _getDayText(),
              style: TextStyle(
                fontSize: _getNumberFontSize(),
                fontWeight: FontWeight.bold,
                color: _getTextColor(),
                height: 1.1,
              ),
            ),

          // Label (hidden for small size or certain states)
          if (size != CountdownSize.small && _getLabelText().isNotEmpty) ...[
            SizedBox(height: size == CountdownSize.large ? 4 : 2),
            Text(
              _getLabelText(),
              style: TextStyle(
                fontSize: _getLabelFontSize(),
                color: _getTextColor(),
                fontWeight: size == CountdownSize.large ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Get the main display text
  String _getDayText() {
    if (isCompleted) return '';
    if (daysRemaining < 0) return '${daysRemaining.abs()}';
    if (daysRemaining == 0) return 'Today';
    if (daysRemaining == 1) return '1';
    return '$daysRemaining';
  }

  /// Get the label text below the number
  String _getLabelText() {
    if (isCompleted) return 'Done';
    if (daysRemaining < 0) {
      return daysRemaining == -1 ? 'day ago' : 'days ago';
    }
    if (daysRemaining == 0) return '';
    if (daysRemaining == 1) return 'day';
    return 'days';
  }

  /// Get background/border color based on urgency
  Color _getBackgroundColor() {
    if (customColor != null) return customColor!;
    if (isCompleted) return AppColors.success;
    if (daysRemaining < 0) return AppColors.error; // Overdue - red
    if (daysRemaining <= 1) return AppColors.error; // 0-1 days - red
    if (daysRemaining <= 3) return AppColors.warning; // 2-3 days - orange/yellow
    if (daysRemaining <= 7) return AppColors.info; // 4-7 days - blue
    return AppColors.success; // 8+ days - green
  }

  /// Get text color (same as background for consistency)
  Color _getTextColor() {
    return _getBackgroundColor();
  }

  // ========== SIZE-SPECIFIC GETTERS ==========

  double _getNumberFontSize() {
    switch (size) {
      case CountdownSize.small:
        return 14;
      case CountdownSize.medium:
        return 20;
      case CountdownSize.large:
        return 40;
    }
  }

  double _getLabelFontSize() {
    switch (size) {
      case CountdownSize.small:
        return 10;
      case CountdownSize.medium:
        return 12;
      case CountdownSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case CountdownSize.small:
        return 16;
      case CountdownSize.medium:
        return 24;
      case CountdownSize.large:
        return 48;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case CountdownSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CountdownSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CountdownSize.large:
        return const EdgeInsets.all(24);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case CountdownSize.small:
        return 6;
      case CountdownSize.medium:
        return 8;
      case CountdownSize.large:
        return 16;
    }
  }
}

/// Compact countdown chip for use in lists
class CountdownChip extends StatelessWidget {
  final int daysRemaining;
  final bool isCompleted;

  const CountdownChip({
    super.key,
    required this.daysRemaining,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return CountdownWidget(
      daysRemaining: daysRemaining,
      isCompleted: isCompleted,
      size: CountdownSize.small,
    );
  }
}

/// Large countdown card for detail screens
class CountdownCard extends StatelessWidget {
  final int daysRemaining;
  final bool isCompleted;
  final String? subtitle;

  const CountdownCard({
    super.key,
    required this.daysRemaining,
    this.isCompleted = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor().withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getBackgroundColor().withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountdownWidget(
              daysRemaining: daysRemaining,
              isCompleted: isCompleted,
              size: CountdownSize.large,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: _getBackgroundColor(),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isCompleted) return AppColors.success;
    if (daysRemaining < 0) return AppColors.error;
    if (daysRemaining <= 1) return AppColors.error;
    if (daysRemaining <= 3) return AppColors.warning;
    if (daysRemaining <= 7) return AppColors.info;
    return AppColors.success;
  }
}
