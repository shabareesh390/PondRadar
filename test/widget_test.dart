import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondradar/config/thresholds.dart';
import 'package:pondradar/l10n/translations.dart';
import 'package:pondradar/widgets/app_banners.dart';
import 'package:pondradar/widgets/risk_badge.dart';

void main() {
  testWidgets('RiskBadge renders Low, Medium, and High risk with icons and labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RiskBadge(risk: WaterRiskLevel.low, language: AppLanguage.en),
              RiskBadge(risk: WaterRiskLevel.medium, language: AppLanguage.en),
              RiskBadge(risk: WaterRiskLevel.high, language: AppLanguage.en),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Low risk'), findsOneWidget);
    expect(find.text('Medium risk'), findsOneWidget);
    expect(find.text('High risk'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('SimulatedDataBanner and Disclaimer render in Kannada and English',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SimulatedDataBanner(language: AppLanguage.kn),
              DisclaimerText(language: AppLanguage.kn),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ಅಣಕು ಡೆಮೊ ಮಾಹಿತಿ'), findsOneWidget);
    expect(find.textContaining('ನಿರ್ಧಾರ-ಬೆಂಬಲ ಸಾಧನ'), findsOneWidget);
  });
}
