/// Note Model
///
/// Represents a study note in the application.
/// Maps to Firestore documents in the 'notes' collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NoteModel {
  /// Firestore document ID
  final String id;

  /// Owner's Firebase user ID
  final String userId;

  /// Note title
  final String title;

  /// Note content (extracted text or typed)
  final String content;

  /// AI-generated summary (optional, for future feature)
  final String? summary;

  /// Firebase Storage URL for uploaded file (optional)
  final String? fileUrl;

  /// File type: 'image', 'pdf', or null for text-only notes
  final String? fileType;

  /// Subject/category (optional)
  final String? subject;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.summary,
    this.fileUrl,
    this.fileType,
    this.subject,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create NoteModel from Firestore DocumentSnapshot
  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel.fromMap(data, doc.id);
  }

  /// Create NoteModel from Map (Firestore data)
  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled',
      content: map['content'] ?? '',
      summary: map['summary'],
      fileUrl: map['fileUrl'],
      fileType: map['fileType'],
      subject: map['subject'],
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Helper to parse Firestore Timestamp or DateTime
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'summary': summary,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'subject': subject,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? summary,
    String? fileUrl,
    String? fileType,
    String? subject,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get display title (fallback to 'Untitled Note')
  String get displayTitle {
    if (title.isNotEmpty) return title;
    return 'Untitled Note';
  }

  /// Get content preview (first 150 characters)
  String get contentPreview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  /// Get formatted date string
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(updatedAt);
  }

  /// Get formatted date with time
  String get formattedDateTime {
    return DateFormat('MMM d, yyyy h:mm a').format(updatedAt);
  }

  /// Check if note has attached file
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Check if note is an image note
  bool get isImageNote => fileType == 'image';

  /// Check if note is a PDF note
  bool get isPdfNote => fileType == 'pdf';

  /// Check if note is an audio note
  bool get isAudioNote => fileType == 'audio';

  /// Check if note is text-only
  bool get isTextOnly => fileType == null;

  /// Get word count
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, fileType: $fileType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
