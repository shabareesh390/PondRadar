import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'features/auth/role_picker_screen.dart';
import 'features/farmer_nav_container.dart';
import 'features/officer/officer_dashboard_screen.dart';
import 'firebase_options.dart';
import 'l10n/translations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from assets/.env (or template fallback)
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: 'assets/.env.example');
    } catch (e) {
      debugPrint('Environment notice: using built-in defaults: $e');
    }
  }

  // Initialize Firebase with auto-configured platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const PondRadarApp());
}

class PondRadarApp extends StatefulWidget {
  const PondRadarApp({super.key});

  @override
  State<PondRadarApp> createState() => _PondRadarAppState();
}

class _PondRadarAppState extends State<PondRadarApp> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final LanguageNotifier _languageNotifier;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
    _languageNotifier = LanguageNotifier();
  }

  @override
  void dispose() {
    _authService.dispose();
    _languageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageNotifier,
      builder: (context, _) {
        final lang = _languageNotifier.currentLanguage;

        return MaterialApp(
          title: AppStrings.get('appName', lang),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routes: {
            '/officer': (ctx) => OfficerDashboardScreen(
              authService: _authService,
              firestoreService: _firestoreService,
              languageNotifier: _languageNotifier,
            ),
          },
          home: ListenableBuilder(
            listenable: _authService,
            builder: (context, _) {
              if (_authService.isLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              // Web direct officer route handling
              if (kIsWeb && Uri.base.path.contains('/officer')) {
                return OfficerDashboardScreen(
                  authService: _authService,
                  firestoreService: _firestoreService,
                  languageNotifier: _languageNotifier,
                );
              }

              if (_authService.role == null) {
                return RolePickerScreen(
                  authService: _authService,
                  languageNotifier: _languageNotifier,
                );
              }

              if (_authService.isOfficer) {
                return OfficerDashboardScreen(
                  authService: _authService,
                  firestoreService: _firestoreService,
                  languageNotifier: _languageNotifier,
                );
              }

              return FarmerNavContainer(
                authService: _authService,
                firestoreService: _firestoreService,
                languageNotifier: _languageNotifier,
              );
            },
          ),
        );
      },
    );
  }
}
