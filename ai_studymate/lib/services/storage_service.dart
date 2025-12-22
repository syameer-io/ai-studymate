/// Storage Service
///
/// Handles file uploads and deletions in Firebase Storage.
/// Uses singleton pattern for consistent access.
///
/// Usage:
///   final storageService = StorageService();
///   final url = await storageService.uploadNoteImage(userId: uid, file: imageFile);

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

/// Custom exception for storage errors
class StorageException implements Exception {
  final String message;
  final String? code;

  const StorageException(this.message, [this.code]);

  @override
  String toString() => message;
}

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // UUID generator
  final Uuid _uuid = const Uuid();

  /// Upload an image file for a note
  ///
  /// [userId] - Current user's Firebase UID
  /// [file] - Image file to upload
  /// [fileName] - Optional custom filename
  ///
  /// Returns download URL on success
  /// Throws [StorageException] on failure
  Future<String> uploadNoteImage({
    required String userId,
    required File file,
    String? fileName,
  }) async {
    try {
      final extension = _getFileExtension(file);
      final name = fileName ?? '${_uuid.v4()}$extension';

      // Path: note_images/{userId}/{filename}
      final path = '${AppConstants.storageNoteImages}/$userId/$name';
      final ref = _storage.ref().child(path);

      // Set metadata for images
      final metadata = SettableMetadata(
        contentType: 'image/${extension.replaceFirst('.', '')}',
      );

      // Upload file
      final uploadTask = await ref.putFile(file, metadata);

      // Get and return download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload image: ${e.message}', e.code);
    } catch (e) {
      throw StorageException('Failed to upload image: $e');
    }
  }

  /// Upload a PDF file for a note
  ///
  /// [userId] - Current user's Firebase UID
  /// [file] - PDF file to upload
  /// [fileName] - Optional custom filename
  ///
  /// Returns download URL on success
  /// Throws [StorageException] on failure
  Future<String> uploadNotePdf({
    required String userId,
    required File file,
    String? fileName,
  }) async {
    try {
      final name = fileName ?? '${_uuid.v4()}.pdf';

      // Path: note_images/{userId}/{filename} (using same folder for simplicity)
      final path = '${AppConstants.storageNoteImages}/$userId/$name';
      final ref = _storage.ref().child(path);

      // Set metadata for PDF
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
      );

      // Upload file
      final uploadTask = await ref.putFile(file, metadata);

      // Get and return download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload PDF: ${e.message}', e.code);
    } catch (e) {
      throw StorageException('Failed to upload PDF: $e');
    }
  }

  /// Upload an audio file for a note
  ///
  /// [userId] - Current user's Firebase UID
  /// [file] - Audio file to upload (m4a, wav, etc.)
  /// [fileName] - Optional custom filename
  ///
  /// Returns download URL on success
  /// Throws [StorageException] on failure
  Future<String> uploadNoteAudio({
    required String userId,
    required File file,
    String? fileName,
  }) async {
    try {
      final extension = _getFileExtension(file);
      final name = fileName ?? '${_uuid.v4()}$extension';

      // Path: audio_files/{userId}/{filename}
      final path = '${AppConstants.storageAudioFiles}/$userId/$name';
      final ref = _storage.ref().child(path);

      // Set metadata for audio (m4a/aac format)
      final metadata = SettableMetadata(
        contentType: extension == '.m4a' ? 'audio/mp4' : 'audio/mpeg',
      );

      // Upload file
      final uploadTask = await ref.putFile(file, metadata);

      // Get and return download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload audio: ${e.message}', e.code);
    } catch (e) {
      throw StorageException('Failed to upload audio: $e');
    }
  }

  /// Upload any file to a specific folder
  ///
  /// [userId] - Current user's Firebase UID
  /// [file] - File to upload
  /// [folder] - Storage folder path
  /// [contentType] - MIME type of the file
  ///
  /// Returns download URL on success
  Future<String> uploadFile({
    required String userId,
    required File file,
    required String folder,
    String? contentType,
  }) async {
    try {
      final extension = _getFileExtension(file);
      final name = '${_uuid.v4()}$extension';

      final path = '$folder/$userId/$name';
      final ref = _storage.ref().child(path);

      SettableMetadata? metadata;
      if (contentType != null) {
        metadata = SettableMetadata(contentType: contentType);
      }

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException('Failed to upload file: ${e.message}', e.code);
    } catch (e) {
      throw StorageException('Failed to upload file: $e');
    }
  }

  /// Delete a file from Firebase Storage by URL
  ///
  /// [fileUrl] - The download URL of the file to delete
  ///
  /// Silently fails if file doesn't exist
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore 'object-not-found' error (file already deleted)
      if (e.code != 'object-not-found') {
        throw StorageException('Failed to delete file: ${e.message}', e.code);
      }
    } catch (e) {
      // Silently handle other errors during deletion
    }
  }

  /// Get the file extension from a File
  String _getFileExtension(File file) {
    final path = file.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot).toLowerCase();
    }
    return '';
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Check if file size is within limit (default 10MB)
  Future<bool> isFileSizeValid(File file, {int maxSizeBytes = 10 * 1024 * 1024}) async {
    final size = await getFileSize(file);
    return size <= maxSizeBytes;
  }
}
