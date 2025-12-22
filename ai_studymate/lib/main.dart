import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Import our configuration
import 'config/theme_config.dart';
import 'config/app_config.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/flashcard_provider.dart';

// Import screens
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

/// Main entry point of the AI StudyMate application
///
/// This function:
/// 1. Initializes Flutter bindings
/// 2. Loads environment variables from .env file
/// 3. Initializes Firebase services
/// 4. Runs the app with providers
void main() async {
  // Ensure Flutter is initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred screen orientations (portrait only for now)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Run the app
  runApp(const AIStudyMateApp());
}

/// Root widget of the application
///
/// Sets up:
/// - State management (Provider)
/// - Theme (colors, fonts, styles)
/// - Authentication wrapper
class AIStudyMateApp extends StatelessWidget {
  const AIStudyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap entire app with providers
    return MultiProvider(
      providers: [
        // Auth provider - manages authentication state
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Notes provider - manages notes state
        ChangeNotifierProvider(create: (_) => NotesProvider()),

        // Flashcard provider - manages flashcards state
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),

        // Add more providers here as we build features
        // ChangeNotifierProvider(create: (_) => ExamProvider()),
      ],
      child: MaterialApp(
        // App title (shown in task switcher)
        title: AppConfig.appName,

        // Hide debug banner in top right corner
        debugShowCheckedModeBanner: false,

        // Apply our custom theme
        theme: AppTheme.lightTheme,

        // Auth wrapper handles login/home navigation
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Authentication Wrapper
///
/// Shows appropriate screen based on authentication state:
/// - Loading: Shows splash screen while checking auth
/// - Authenticated: Shows HomeScreen
/// - Unauthenticated: Shows LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch auth provider for changes
    final authProvider = context.watch<AuthProvider>();

    // Show loading while initializing auth state
    if (authProvider.isInitializing) {
      return const _SplashScreen();
    }

    // Show Login or Home based on auth state
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

/// Splash Screen
///
/// Shown while checking authentication state.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Icon(
              Icons.school,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConfig.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
