import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondradar/config/theme.dart';
import 'package:pondradar/features/auth/role_picker_screen.dart';
import 'package:pondradar/features/officer/officer_dashboard_screen.dart';
import 'package:pondradar/features/ponds/add_pond_screen.dart';
import 'package:pondradar/features/ponds/farmer_home_screen.dart';
import 'package:pondradar/features/reports/report_problem_screen.dart';
import 'package:pondradar/features/water_check/water_check_screen.dart';
import 'package:pondradar/l10n/translations.dart';
import 'package:pondradar/models/pond.dart';
import 'package:pondradar/services/auth_service.dart';
import 'package:pondradar/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Responsiveness & Layout Scalability Tests', () {
    testWidgets(
        'RolePickerScreen renders on 320x480 phone with PIN input open without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      await langNotifier.setLanguage(AppLanguage.kn);
      final authService = AuthService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.2),
              size: Size(320, 480),
              viewInsets: EdgeInsets.only(bottom: 180), // Simulating keyboard
            ),
            child: RolePickerScreen(
              authService: authService,
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final officerFinder = find.text(AppStrings.get('officerRole', AppLanguage.kn));
      await tester.ensureVisible(officerFinder);
      await tester.tap(officerFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RolePickerScreen), findsOneWidget);
    });

    testWidgets(
        'WaterCheckScreen renders evaluated result on 360px phone at 1.3x font scale without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      await langNotifier.setLanguage(AppLanguage.kn);

      final pond = Pond(
        id: 'test_p1',
        userId: 'u1',
        name: 'ಕೊಳ 1 - ಉಡುಪಿ',
        latitude: 13.34,
        longitude: 74.74,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
              size: Size(360, 640),
            ),
            child: WaterCheckScreen(
              pond: pond,
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap evaluate risk button
      final evalBtn = find.text(AppStrings.get('evaluateRisk', AppLanguage.kn));
      await tester.ensureVisible(evalBtn);
      await tester.tap(evalBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WaterCheckScreen), findsOneWidget);
    });

    testWidgets(
        'ReportProblemScreen renders symptom grid on 360px phone at 1.3x text scale without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      await langNotifier.setLanguage(AppLanguage.kn);

      final pond = Pond(
        id: 'test_p1',
        userId: 'u1',
        name: 'ಕೊಳ 1 - ಉಡುಪಿ',
        latitude: 13.34,
        longitude: 74.74,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
              size: Size(360, 640),
            ),
            child: ReportProblemScreen(
              userId: 'u1',
              ponds: [pond],
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ReportProblemScreen), findsOneWidget);
    });

    testWidgets(
        'FarmerHomeScreen renders on 320px phone with Kannada text without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      await langNotifier.setLanguage(AppLanguage.kn);

      final pond = Pond(
        id: 'test_p1',
        userId: 'u1',
        name: 'ಕೊಳ 1 - ಉಡುಪಿ ಕರಾವಳಿ ಫಾರ್ಮ್',
        latitude: 13.34,
        longitude: 74.74,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.2),
              size: Size(320, 568),
            ),
            child: FarmerHomeScreen(
              userId: 'u1',
              ponds: [pond],
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FarmerHomeScreen), findsOneWidget);
    });

    testWidgets(
        'AddPondScreen renders location row on 320px phone with Kannada text without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      await langNotifier.setLanguage(AppLanguage.kn);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.2),
              size: Size(320, 568),
            ),
            child: AddPondScreen(
              userId: 'u1',
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AddPondScreen), findsOneWidget);
    });

    testWidgets(
        'OfficerDashboardScreen renders full-width mobile layout with Drawer and NavigationBar on 360px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      final authService = AuthService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
            ),
            child: OfficerDashboardScreen(
              authService: authService,
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets(
        'OfficerDashboardScreen renders multi-column desktop layout on 1024px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      final authService = AuthService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
            ),
            child: OfficerDashboardScreen(
              authService: authService,
              firestoreService: FirestoreService(),
              languageNotifier: langNotifier,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final err = tester.takeException();
      if (err is FlutterError) {
        debugPrint('OVERFLOW DETAILS: ${err.toStringDeep()}');
      }
      expect(err, isNull);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
