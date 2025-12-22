/// Authentication Service
///
/// Wraps Firebase Authentication to provide simple methods
/// for login, register, and logout operations.
///
/// Usage:
///   final authService = AuthService();
///   await authService.signInWithEmail('user@email.com', 'password');

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In instance with explicit configuration
  // The serverClientId is the Web client ID from Firebase Console
  // This is needed to get the idToken for Firebase authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web client ID from google-services.json (client_type: 3)
    serverClientId: '638154843560-iuun2gp3afpk1f1942apjsl4jpdppm3v.apps.googleusercontent.com',
  );

  /// Stream of auth state changes
  ///
  /// Emits the current user whenever auth state changes.
  /// Used by AuthProvider to reactively update UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Register new user with email and password
  ///
  /// [email] - User's email address
  /// [password] - Password (min 6 characters)
  /// [displayName] - Optional display name
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create user account in Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        // Reload user to get updated data
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  /// Sign in with email and password
  ///
  /// [email] - User's email address
  /// [password] - User's password
  ///
  /// Returns [UserCredential] on success
  /// Throws [AuthException] on failure
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  /// Sign in with Google account
  ///
  /// Opens Google sign-in popup, then authenticates with Firebase.
  ///
  /// Returns [UserCredential] on success
  /// Returns null if user cancelled
  /// Throws [AuthException] on error
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure clean state and allow account selection
      await _googleSignIn.signOut();

      // Trigger Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled sign-in
      if (googleUser == null) {
        return null;
      }

      // Get auth credentials from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verify we got the required tokens
      if (googleAuth.idToken == null) {
        throw AuthException(
          'Failed to get ID token from Google. Please ensure SHA-1 fingerprint is registered in Firebase Console.',
          'missing-id-token',
        );
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      // Check for common Google Sign-In errors
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('10:') || errorMessage.contains('developer_error')) {
        throw AuthException(
          'Google Sign-In configuration error. Please verify:\n'
          '1. SHA-1 fingerprint is added to Firebase Console\n'
          '2. google-services.json is up to date\n'
          '3. Google Sign-In is enabled in Firebase Auth',
          'developer-error',
        );
      }
      if (errorMessage.contains('12500') || errorMessage.contains('sign_in_failed')) {
        throw AuthException(
          'Google Sign-In failed. Please try again.',
          'sign-in-failed',
        );
      }
      if (errorMessage.contains('network')) {
        throw AuthException(
          'Network error. Please check your internet connection.',
          'network-error',
        );
      }
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Sign out current user
  ///
  /// Signs out from both Firebase and Google (if applicable).
  Future<void> signOut() async {
    try {
      // Sign out from Google first (if signed in with Google)
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  /// Update user's display name
  Future<void> updateDisplayName(String name) async {
    try {
      await currentUser?.updateDisplayName(name.trim());
      await currentUser?.reload();
    } catch (e) {
      throw AuthException('Failed to update display name: $e');
    }
  }

  /// Update user's profile photo
  Future<void> updatePhotoUrl(String url) async {
    try {
      await currentUser?.updatePhotoURL(url);
      await currentUser?.reload();
    } catch (e) {
      throw AuthException('Failed to update profile photo: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      throw AuthException('Failed to send verification email: $e');
    }
  }

  /// Get Firebase ID token (for Laravel API calls)
  ///
  /// This token proves the user is authenticated.
  /// Send it in Authorization header: "Bearer <token>"
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      return null;
    }
  }

  /// Reload current user data
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
