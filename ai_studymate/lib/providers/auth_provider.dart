/// Authentication State Provider
///
/// Manages auth state and exposes it to the widget tree.
/// Uses ChangeNotifier to notify widgets when state changes.
///
/// Usage:
///   Provider.of<AuthProvider>(context).user
///   context.watch<AuthProvider>().isLoading

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication state
enum AuthState {
  /// Initial state, checking if user is logged in
  initial,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Stream subscription for auth state changes
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  // Current auth state
  AuthState _authState = AuthState.initial;
  AuthState get authState => _authState;

  // Current user model (null if not logged in)
  UserModel? _user;
  UserModel? get user => _user;

  // Loading state for async operations
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message from last operation
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Convenience getters
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isInitializing => _authState == AuthState.initial;
  String get displayName => _user?.displayNameOrEmail ?? 'User';
  String get email => _user?.email ?? '';
  String get uid => _user?.uid ?? '';
  String get initials => _user?.initials ?? 'U';
  String? get photoUrl => _user?.photoUrl;

  /// Initialize provider - listen to auth changes
  AuthProvider() {
    _init();
  }

  /// Initialize auth state listener
  void _init() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error) {
        _authState = AuthState.unauthenticated;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Called when auth state changes
  void _onAuthStateChanged(firebase_auth.User? firebaseUser) {
    if (firebaseUser != null) {
      _user = UserModel.fromFirebaseUser(firebaseUser);
      _authState = AuthState.authenticated;
    } else {
      _user = null;
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Register with email and password
  ///
  /// Returns true on success, false on failure.
  /// Check [errorMessage] for failure reason.
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  ///
  /// Returns true on success, false on failure.
  /// Check [errorMessage] for failure reason.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  ///
  /// Returns true on success, false on failure or cancellation.
  /// Check [errorMessage] for failure reason.
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final result = await _authService.signInWithGoogle();

      // User cancelled
      if (result == null) {
        _errorMessage = 'Sign-in cancelled';
        return false;
      }

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _authService.signOut();
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Sign out failed.';
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  ///
  /// Returns true on success, false on failure.
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send password reset email.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String name) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.updateDisplayName(name);

      // Update local user model
      if (_user != null) {
        _user = _user!.copyWith(displayName: name);
        notifyListeners();
      }

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update name.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get Firebase ID token for API calls
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _authService.getIdToken(forceRefresh: forceRefresh);
  }

  /// Reload user data from Firebase
  Future<void> reloadUser() async {
    await _authService.reloadUser();
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = UserModel.fromFirebaseUser(firebaseUser);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
