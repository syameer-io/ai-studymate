/// Login Screen
///
/// Allows users to sign in with:
/// - Email and password
/// - Google account

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Handle email/password login
  Future<void> _handleEmailLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      // Show error snackbar
      _showErrorSnackBar(authProvider.errorMessage ?? 'Login failed');
    }
    // Success: AuthProvider will update state, AuthWrapper will redirect to home
  }

  /// Handle Google sign-in
  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithGoogle();

    if (!success && mounted) {
      // Don't show error if user just cancelled
      final error = authProvider.errorMessage;
      if (error != null && error != 'Sign-in cancelled') {
        _showErrorSnackBar(error);
      }
    }
  }

  /// Handle forgot password
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email first');
      return;
    }

    if (!email.contains('@')) {
      _showErrorSnackBar('Please enter a valid email');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordReset(email);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('Password reset email sent to $email');
      } else {
        _showErrorSnackBar(
            authProvider.errorMessage ?? 'Failed to send reset email');
      }
    }
  }

  /// Navigate to register screen
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // App logo and title
                _buildHeader(),
                const SizedBox(height: 48),

                // Email field
                EmailTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  validator: Validators.validateEmail,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),

                // Password field
                PasswordTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  validator: Validators.validatePassword,
                  onSubmitted: (_) => _handleEmailLogin(),
                ),
                const SizedBox(height: 8),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return LoadingButton(
                      isLoading: auth.isLoading,
                      onPressed: _handleEmailLogin,
                      label: 'Sign In',
                      width: double.infinity,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Divider with "OR"
                _buildDivider(),
                const SizedBox(height: 24),

                // Google sign-in button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return _GoogleSignInButton(
                      isLoading: auth.isLoading,
                      onPressed: _handleGoogleLogin,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Register link
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.school,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'AI StudyMate',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back! Sign in to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _goToRegister,
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

/// Google Sign-In Button
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.textLight),
      ),
      child: isLoading
          ? const SmallLoadingIndicator()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google logo
                Image.network(
                  'https://www.google.com/favicon.ico',
                  height: 24,
                  width: 24,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
