/// PDF Service
///
/// Extracts text from PDF files using Syncfusion Flutter PDF.
/// Uses singleton pattern for consistent access.
///
/// Note: Syncfusion provides a free community license for
/// individuals and small businesses with revenue < $1M USD.
///
/// Usage:
///   final pdfService = PdfService();
///   final text = await pdfService.extractTextFromPdf(pdfFile);

import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Custom exception for PDF errors
class PdfException implements Exception {
  final String message;

  const PdfException(this.message);

  @override
  String toString() => message;
}

class PdfService {
  // Singleton pattern
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// Extract text from a PDF file
  ///
  /// [pdfFile] - The PDF file to process
  ///
  /// Returns extracted text as a string
  /// Throws [PdfException] if extraction fails or no text found
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      // Validate file exists
      if (!await pdfFile.exists()) {
        throw const PdfException('PDF file does not exist');
      }

      // Read PDF file bytes
      final bytes = await pdfFile.readAsBytes();

      // Load PDF document
      final document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      final StringBuffer extractedText = StringBuffer();

      // Create text extractor
      final textExtractor = PdfTextExtractor(document);

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = textExtractor.extractText(startPageIndex: i);
        if (pageText.isNotEmpty) {
          extractedText.writeln(pageText);
          extractedText.writeln(); // Add blank line between pages
        }
      }

      // Dispose document to free resources
      document.dispose();

      final result = extractedText.toString().trim();

      // Check if any text was found
      if (result.isEmpty) {
        throw const PdfException('No text found in PDF. The PDF may contain only images.');
      }

      return result;
    } on PdfException {
      rethrow;
    } catch (e) {
      throw PdfException('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from a PDF file path
  ///
  /// [pdfPath] - Path to the PDF file
  ///
  /// Returns extracted text as a string
  Future<String> extractTextFromPath(String pdfPath) async {
    return extractTextFromPdf(File(pdfPath));
  }

  /// Get the number of pages in a PDF
  ///
  /// [pdfFile] - The PDF file to analyze
  ///
  /// Returns the page count
  Future<int> getPageCount(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      throw PdfException('Failed to read PDF: $e');
    }
  }

  /// Extract text from specific pages
  ///
  /// [pdfFile] - The PDF file to process
  /// [startPage] - Starting page index (0-based)
  /// [endPage] - Ending page index (0-based, inclusive)
  ///
  /// Returns extracted text as a string
  Future<String> extractTextFromPages(
    File pdfFile, {
    required int startPage,
    required int endPage,
  }) async {
    try {
      if (!await pdfFile.exists()) {
        throw const PdfException('PDF file does not exist');
      }

      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Validate page range
      if (startPage < 0 || endPage >= document.pages.count) {
        document.dispose();
        throw const PdfException('Invalid page range');
      }

      final textExtractor = PdfTextExtractor(document);
      final text = textExtractor.extractText(
        startPageIndex: startPage,
        endPageIndex: endPage,
      );

      document.dispose();

      if (text.isEmpty) {
        throw const PdfException('No text found in specified pages');
      }

      return text;
    } on PdfException {
      rethrow;
    } catch (e) {
      throw PdfException('Failed to extract text from PDF: $e');
    }
  }

  /// Check if a file is a valid PDF
  ///
  /// [file] - File to check
  ///
  /// Returns true if the file is a valid PDF
  Future<bool> isValidPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Check PDF magic number (starts with %PDF-)
      if (bytes.length < 5) return false;
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      return header == '%PDF-';
    } catch (e) {
      return false;
    }
  }
}
