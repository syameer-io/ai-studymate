/// OCR Service
///
/// Extracts text from images using Google ML Kit.
/// Uses singleton pattern with proper resource management.
///
/// Usage:
///   final ocrService = OcrService();
///   final text = await ocrService.extractTextFromImage(imageFile);

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/constants.dart';

/// Custom exception for OCR errors
class OcrException implements Exception {
  final String message;

  const OcrException(this.message);

  @override
  String toString() => message;
}

class OcrService {
  // Singleton pattern
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // Text recognizer instance (lazy initialization)
  TextRecognizer? _textRecognizer;

  /// Get or create text recognizer instance
  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Extract text from an image file
  ///
  /// [imageFile] - The image file to process
  ///
  /// Returns extracted text as a string
  /// Throws [OcrException] if extraction fails or no text found
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw const OcrException('Image file does not exist');
      }

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process the image
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Check if any text was found
      if (recognizedText.text.isEmpty) {
        throw OcrException(ErrorMessages.noTextFound);
      }

      // Return the full recognized text
      return recognizedText.text;
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('${ErrorMessages.ocrFailed}: $e');
    }
  }

  /// Extract text from an image path
  ///
  /// [imagePath] - Path to the image file
  ///
  /// Returns extracted text as a string
  Future<String> extractTextFromPath(String imagePath) async {
    return extractTextFromImage(File(imagePath));
  }

  /// Extract text with block-level details
  ///
  /// Returns a list of text blocks with their bounding boxes
  /// Useful for more advanced text processing
  Future<List<TextBlockInfo>> extractTextBlocks(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw const OcrException('Image file does not exist');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        throw OcrException(ErrorMessages.noTextFound);
      }

      return recognizedText.blocks.map((block) {
        return TextBlockInfo(
          text: block.text,
          lines: block.lines.map((line) => line.text).toList(),
          cornerPoints: block.cornerPoints,
        );
      }).toList();
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('${ErrorMessages.ocrFailed}: $e');
    }
  }

  /// Format extracted text with proper line breaks and spacing
  ///
  /// Processes raw OCR text to improve readability
  String formatExtractedText(String rawText) {
    // Split into lines and remove empty lines
    final lines = rawText.split('\n').where((line) => line.trim().isNotEmpty);

    // Join with single newlines
    return lines.join('\n');
  }

  /// Clean up resources
  ///
  /// Call this when the service is no longer needed
  /// (e.g., when the app is disposed)
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

/// Information about a text block
class TextBlockInfo {
  final String text;
  final List<String> lines;
  final List<dynamic> cornerPoints;

  const TextBlockInfo({
    required this.text,
    required this.lines,
    required this.cornerPoints,
  });
}
