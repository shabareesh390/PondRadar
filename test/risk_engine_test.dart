import 'package:flutter_test/flutter_test.dart';
import 'package:pondradar/config/thresholds.dart';
import 'package:pondradar/features/water_check/risk_engine.dart';

void main() {
  group('Aquaculture RiskEngine Unit Tests', () {
    test('All optimal parameters return Low risk', () {
      final result = RiskEngine.evaluate(
        ph: 8.0,
        dissolvedOxygen: 5.5,
        ammonia: 0.05,
        temperature: 28.0,
      );

      expect(result.overallRisk, WaterRiskLevel.low);
      expect(result.parameterResults.length, 4);
      for (final p in result.parameterResults) {
        expect(p.risk, WaterRiskLevel.low);
      }
      expect(result.actionNoteEn, contains('stable'));
    });

    test('Single medium parameter elevates overall risk to Medium', () {
      final result = RiskEngine.evaluate(
        ph: 7.2, // Medium
        dissolvedOxygen: 5.0, // Low
        ammonia: 0.05, // Low
        temperature: 28.0, // Low
      );

      expect(result.overallRisk, WaterRiskLevel.medium);
      final phResult = result.parameterResults.firstWhere((p) => p.key == 'ph');
      expect(phResult.risk, WaterRiskLevel.medium);
      expect(phResult.reasonEn, contains('slightly acidic'));
    });

    test('Single high parameter elevates overall risk to High', () {
      final result = RiskEngine.evaluate(
        ph: 8.0,
        dissolvedOxygen: 2.2, // Dangerously low (<3.0)
        ammonia: 0.05,
        temperature: 28.0,
      );

      expect(result.overallRisk, WaterRiskLevel.high);
      final doResult = result.parameterResults.firstWhere(
        (p) => p.key == 'dissolvedOxygen',
      );
      expect(doResult.risk, WaterRiskLevel.high);
      expect(doResult.reasonEn, contains('dangerously low'));
      expect(result.actionNoteEn, contains('aerators immediately'));
    });

    test('Worst parameter rule governs overall risk', () {
      // pH: medium (7.2), DO: high (2.5), ammonia: low (0.05), temp: medium (33.0)
      final result = RiskEngine.evaluate(
        ph: 7.2,
        dissolvedOxygen: 2.5,
        ammonia: 0.05,
        temperature: 33.0,
      );

      expect(result.overallRisk, WaterRiskLevel.high);
    });

    test('Ammonia toxic threshold (>0.3) triggers High risk and reduction note', () {
      final result = RiskEngine.evaluate(
        ph: 8.0,
        dissolvedOxygen: 5.0,
        ammonia: 0.45,
        temperature: 28.0,
      );

      expect(result.overallRisk, WaterRiskLevel.high);
      final ammResult = result.parameterResults.firstWhere(
        (p) => p.key == 'ammonia',
      );
      expect(ammResult.risk, WaterRiskLevel.high);
      expect(result.actionNoteEn, contains('Reduce feed'));
    });

    test('Kannada translations are provided for all parameters and action notes', () {
      final result = RiskEngine.evaluate(
        ph: 6.5, // High
        dissolvedOxygen: 4.5,
        ammonia: 0.05,
        temperature: 28.0,
      );

      expect(result.actionNoteKn.isNotEmpty, true);
      for (final p in result.parameterResults) {
        expect(p.reasonKn.isNotEmpty, true);
        expect(p.nameKn.isNotEmpty, true);
      }
    });
  });
}
