/// Form validation utilities
///
/// Provides reusable validation functions for forms throughout the app.
/// All validators return null if valid, or an error message string if invalid.

import 'constants.dart';

class Validators {
  // Prevent instantiation
  Validators._();

  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email address
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.emailRequired;
    }

    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return ErrorMessages.emailInvalid;
    }

    return null;
  }

  /// Validates password
  ///
  /// Checks minimum length requirement.
  /// Returns null if valid, error message if invalid.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.passwordRequired;
    }

    if (value.length < AppConstants.minPasswordLength) {
      return ErrorMessages.passwordTooShort;
    }

    return null;
  }

  /// Validates password confirmation
  ///
  /// Checks that it matches the original password.
  static String? validateConfirmPassword(String? value, String originalPassword) {
    final passwordError = validatePassword(value);
    if (passwordError != null) {
      return passwordError;
    }

    if (value != originalPassword) {
      return ErrorMessages.passwordsDoNotMatch;
    }

    return null;
  }

  /// Validates required text field
  ///
  /// Returns null if valid, error message if empty.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates name field
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.nameRequired;
    }
    return null;
  }

  /// Validates note title
  static String? validateNoteTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.titleRequired;
    }

    if (value.length > AppConstants.maxTitleLength) {
      return 'Title must be less than ${AppConstants.maxTitleLength} characters';
    }

    return null;
  }

  /// Validates note content
  static String? validateNoteContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.contentRequired;
    }

    if (value.length > AppConstants.maxContentLength) {
      return 'Content is too long';
    }

    return null;
  }

  /// Validates flashcard question
  static String? validateFlashcardQuestion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.questionRequired;
    }
    return null;
  }

  /// Validates flashcard answer
  static String? validateFlashcardAnswer(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.answerRequired;
    }
    return null;
  }
}

/// Extension methods for String validation
extension StringValidation on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Check if string is a valid email
  bool get isValidEmail {
    if (isNullOrEmpty) return false;
    return Validators.validateEmail(this) == null;
  }
}
