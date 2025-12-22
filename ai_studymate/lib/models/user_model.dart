/// User Model
///
/// Represents a user in the application.
/// Maps to Firebase Auth User with additional app-specific fields.

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  /// Firebase user ID
  final String uid;

  /// User's email address
  final String email;

  /// User's display name (optional)
  final String? displayName;

  /// Profile photo URL (optional)
  final String? photoUrl;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Last sign-in timestamp
  final DateTime? lastSignInAt;

  /// Whether email is verified
  final bool emailVerified;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.lastSignInAt,
    this.emailVerified = false,
  });

  /// Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
      emailVerified: user.emailVerified,
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      lastSignInAt: map['lastSignInAt'] != null
          ? DateTime.tryParse(map['lastSignInAt'])
          : null,
      emailVerified: map['emailVerified'] ?? false,
    );
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'emailVerified': emailVerified,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? emailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  /// Get display name or email prefix as fallback
  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    // Return part before @ in email
    return email.split('@').first;
  }

  /// Get user initials for avatar
  String get initials {
    final name = displayNameOrEmail;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
