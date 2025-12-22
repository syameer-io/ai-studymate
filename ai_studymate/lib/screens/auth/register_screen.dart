/// Register Screen
///
/// Allows new users to create an account with:
/// - Full name
/// - Email
/// - Password

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  /// Handle registration
  Future<void> _handleRegister() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Registration successful - user is now logged in
        // AuthWrapper will redirect to home automatically
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showSuccessSnackBar('Account created successfully!');
      } else {
        _showErrorSnackBar(
            authProvider.errorMessage ?? 'Registration failed');
      }
    }
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
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Name field
                CustomTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateName,
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),
                const SizedBox(height: 16),

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
                  helperText: 'At least 6 characters',
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                  onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),

                // Confirm password field
                PasswordTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  labelText: 'Confirm Password',
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 32),

                // Register button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return LoadingButton(
                      isLoading: auth.isLoading,
                      onPressed: _handleRegister,
                      label: 'Create Account',
                      width: double.infinity,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Terms and privacy
                _buildTermsText(),
                const SizedBox(height: 24),

                // Login link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join AI StudyMate',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create an account to start studying smarter.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By creating an account, you agree to our Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
