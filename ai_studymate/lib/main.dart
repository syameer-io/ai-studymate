import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Import our configuration
import 'config/theme_config.dart';
import 'config/app_config.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/study_plan_provider.dart';

// Import services
import 'services/notification_service.dart';

// Import screens
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/exams/exam_detail_screen.dart';

/// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Pending notification payload to handle when app is ready
String? _pendingNotificationPayload;

/// Main entry point of the AI StudyMate application
///
/// This function:
/// 1. Initializes Flutter bindings
/// 2. Loads environment variables from .env file
/// 3. Initializes Firebase services
/// 4. Initializes notification service
/// 5. Runs the app with providers
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

  // Set up FCM background handler (must be top-level function)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions (Android 13+)
  await notificationService.requestPermissions();

  // Set up notification tap handler
  NotificationService.onNotificationTap = _handleNotificationTap;

  // Check for notification that launched the app (cold start)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _pendingNotificationPayload = jsonEncode(initialMessage.data);
  }

  // Run the app
  runApp(const AIStudyMateApp());
}

/// Handle notification tap - navigate to appropriate screen
///
/// This is called when user taps a notification.
/// The payload contains JSON data about the notification type.
void _handleNotificationTap(String? payload) {
  if (payload == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final type = data['type'] as String?;

    debugPrint('Handling notification tap: $type');

    // Use post-frame callback to ensure navigator is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('Navigator not available, storing payload for later');
        _pendingNotificationPayload = payload;
        return;
      }

      _navigateFromNotification(navigator, type, data);
    });
  } catch (e) {
    debugPrint('Error handling notification tap: $e');
  }
}

/// Navigate based on notification type
void _navigateFromNotification(
  NavigatorState navigator,
  String? type,
  Map<String, dynamic> data,
) {
  switch (type) {
    case 'exam_reminder':
      final examId = data['examId'];
      if (examId != null) {
        final id = examId is int ? examId : int.parse(examId.toString());
        // Navigate to exam detail screen
        // The ExamDetailScreen uses selectedExam from provider,
        // so we need to select the exam first via the context
        navigator.push(
          MaterialPageRoute(
            builder: (context) {
              // Select the exam in provider before showing detail screen
              final examProvider = context.read<ExamProvider>();
              final exam = examProvider.getExamById(id);
              if (exam != null) {
                examProvider.selectExam(exam);
              }
              return const ExamDetailScreen();
            },
          ),
        );
      }
      break;
    case 'daily_study':
      // Navigate to home screen (notes tab)
      // The home screen is already shown by default
      break;
    default:
      debugPrint('Unknown notification type: $type');
      break;
  }
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

        // Exam provider - manages exams state
        ChangeNotifierProvider(create: (_) => ExamProvider()),

        // Notification provider - manages notification preferences
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // Study plan provider - manages study plans state
        ChangeNotifierProvider(create: (_) => StudyPlanProvider()),
      ],
      child: MaterialApp(
        // Navigator key for notification navigation
        navigatorKey: navigatorKey,

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
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasHandledPendingNotification = false;

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
      // Handle pending notification after authentication
      if (!_hasHandledPendingNotification && _pendingNotificationPayload != null) {
        _hasHandledPendingNotification = true;
        // Process pending notification after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(_pendingNotificationPayload);
          _pendingNotificationPayload = null;
        });
      }
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
