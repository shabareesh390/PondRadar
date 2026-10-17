import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondradar/config/theme.dart';
import 'package:pondradar/features/reports/report_problem_screen.dart';
import 'package:pondradar/features/water_check/water_check_screen.dart';
import 'package:pondradar/l10n/translations.dart';
import 'package:pondradar/models/pond.dart';
import 'package:pondradar/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Responsiveness & Layout Scalability Tests', () {
    testWidgets(
        'WaterCheckScreen renders on 360px phone at 1.3x font scale without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final langNotifier = LanguageNotifier();
      final pond = Pond(
        id: 'test_p1',
        userId: 'u1',
        name: 'Pond 1 - Udupi',
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

      await tester.pump();
      expect(find.byType(WaterCheckScreen), findsOneWidget);
    });

    testWidgets(
        'Kannada text renders on 360px width at 1.3x text scale without clipping',
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

      await tester.pump();
      expect(find.byType(ReportProblemScreen), findsOneWidget);
    });
  });
}
