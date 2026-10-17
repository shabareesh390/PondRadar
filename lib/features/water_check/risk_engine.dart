import '../../config/thresholds.dart';

/// Pure, client-side Risk Engine for Aquaculture Water Quality.
/// Evaluates pH, Dissolved Oxygen, Ammonia, and Temperature against
/// defined thresholds and determines worst-case overall risk level.
class RiskEngine {
  /// Evaluates water parameters and returns structured risk evaluation.
  static WaterRiskEvaluation evaluate({
    required double ph,
    required double dissolvedOxygen,
    required double ammonia,
    required double temperature,
  }) {
    final phResult = _evaluatePh(ph);
    final doResult = _evaluateDo(dissolvedOxygen);
    final ammoniaResult = _evaluateAmmonia(ammonia);
    final tempResult = _evaluateTemperature(temperature);

    final results = [phResult, doResult, ammoniaResult, tempResult];

    // Overall risk = worst parameter
    var worst = WaterRiskLevel.low;
    for (final r in results) {
      if (r.risk.severity > worst.severity) {
        worst = r.risk;
      }
    }

    final actionNotes = _generateActionNote(worst, results);

    return WaterRiskEvaluation(
      overallRisk: worst,
      parameterResults: results,
      actionNoteEn: actionNotes['en']!,
      actionNoteKn: actionNotes['kn']!,
      evaluatedAt: DateTime.now(),
    );
  }

  static ParameterResult _evaluatePh(double ph) {
    WaterRiskLevel risk;
    String reasonEn;
    String reasonKn;

    if (ph >= WaterThresholds.phLowMin && ph <= WaterThresholds.phLowMax) {
      risk = WaterRiskLevel.low;
      reasonEn = 'pH is optimal (7.5 - 8.5)';
      reasonKn = 'ಪಿಹೆಚ್ ಸಮತೋಲನದಲ್ಲಿದೆ (7.5 - 8.5)';
    } else if ((ph >= WaterThresholds.phMedLowMin &&
            ph < WaterThresholds.phLowMin) ||
        (ph > WaterThresholds.phLowMax && ph <= WaterThresholds.phMedHighMax)) {
      risk = WaterRiskLevel.medium;
      if (ph < WaterThresholds.phLowMin) {
        reasonEn = 'pH is slightly acidic (7.0 - 7.5)';
        reasonKn = 'ಪಿಹೆಚ್ ಸ್ವಲ್ಪ ಆಮ್ಲೀಯವಾಗಿದೆ (7.0 - 7.5)';
      } else {
        reasonEn = 'pH is slightly alkaline (8.5 - 9.5)';
        reasonKn = 'ಪಿಹೆಚ್ ಸ್ವಲ್ಪ ಕ್ಷಾರೀಯವಾಗಿದೆ (8.5 - 9.5)';
      }
    } else {
      risk = WaterRiskLevel.high;
      if (ph < WaterThresholds.phMedLowMin) {
        reasonEn = 'pH is critically acidic (< 7.0)';
        reasonKn = 'ಪಿಹೆಚ್ ಅತ್ಯಂತ ಆಮ್ಲೀಯವಾಗಿದೆ (< 7.0)';
      } else {
        reasonEn = 'pH is critically alkaline (> 9.5)';
        reasonKn = 'ಪಿಹೆಚ್ ಅತ್ಯಂತ ಕ್ಷಾರೀಯವಾಗಿದೆ (> 9.5)';
      }
    }

    return ParameterResult(
      key: 'ph',
      nameEn: 'pH',
      nameKn: 'ಪಿಹೆಚ್ (pH)',
      value: ph,
      unit: '',
      risk: risk,
      reasonEn: reasonEn,
      reasonKn: reasonKn,
    );
  }

  static ParameterResult _evaluateDo(double doVal) {
    WaterRiskLevel risk;
    String reasonEn;
    String reasonKn;

    if (doVal >= WaterThresholds.doLowMin) {
      risk = WaterRiskLevel.low;
      reasonEn = 'Dissolved oxygen is sufficient (>= 4.0 mg/L)';
      reasonKn = 'ಕರಗಿದ ಆಮ್ಲಜನಕ ಸಮರ್ಪಕವಾಗಿದೆ (>= 4.0 mg/L)';
    } else if (doVal >= WaterThresholds.doMedMin &&
        doVal < WaterThresholds.doLowMin) {
      risk = WaterRiskLevel.medium;
      reasonEn = 'Dissolved oxygen is borderline (3.0 - 4.0 mg/L)';
      reasonKn = 'ಕರಗಿದ ಆಮ್ಲಜನಕ ಕಡಿಮೆ ಮಟ್ಟದಲ್ಲಿದೆ (3.0 - 4.0 mg/L)';
    } else {
      risk = WaterRiskLevel.high;
      reasonEn = 'Dissolved oxygen is dangerously low (< 3.0 mg/L)';
      reasonKn = 'ಕರಗಿದ ಆಮ್ಲಜನಕ ಅತ್ಯಂತ ಕಡಿಮೆಯಾಗಿದೆ (< 3.0 mg/L)';
    }

    return ParameterResult(
      key: 'dissolvedOxygen',
      nameEn: 'Dissolved Oxygen',
      nameKn: 'ಕರಗಿದ ಆಮ್ಲಜನಕ',
      value: doVal,
      unit: 'mg/L',
      risk: risk,
      reasonEn: reasonEn,
      reasonKn: reasonKn,
    );
  }

  static ParameterResult _evaluateAmmonia(double ammonia) {
    WaterRiskLevel risk;
    String reasonEn;
    String reasonKn;

    if (ammonia <= WaterThresholds.ammoniaLowMax) {
      risk = WaterRiskLevel.low;
      reasonEn = 'Ammonia is within safe range (<= 0.1 mg/L)';
      reasonKn = 'ಅಮೋನಿಯಾ ಸುರಕ್ಷಿತ ಮಿತಿಯಲ್ಲಿದೆ (<= 0.1 mg/L)';
    } else if (ammonia <= WaterThresholds.ammoniaMedMax) {
      risk = WaterRiskLevel.medium;
      reasonEn = 'Ammonia is elevated (0.1 - 0.3 mg/L)';
      reasonKn = 'ಅಮೋನಿಯಾ ಮಟ್ಟ ಏರಿಕೆಯಾಗಿದೆ (0.1 - 0.3 mg/L)';
    } else {
      risk = WaterRiskLevel.high;
      reasonEn = 'Ammonia is toxic (> 0.3 mg/L)';
      reasonKn = 'ಅಮೋನಿಯಾ ಅಪಾಯಕಾರಿ ಮಟ್ಟದಲ್ಲಿದೆ (> 0.3 mg/L)';
    }

    return ParameterResult(
      key: 'ammonia',
      nameEn: 'Ammonia',
      nameKn: 'ಅಮೋನಿಯಾ',
      value: ammonia,
      unit: 'mg/L',
      risk: risk,
      reasonEn: reasonEn,
      reasonKn: reasonKn,
    );
  }

  static ParameterResult _evaluateTemperature(double temp) {
    WaterRiskLevel risk;
    String reasonEn;
    String reasonKn;

    if (temp >= WaterThresholds.tempLowMin &&
        temp <= WaterThresholds.tempLowMax) {
      risk = WaterRiskLevel.low;
      reasonEn = 'Temperature is optimal (26 - 32 C)';
      reasonKn = 'ತಾಪಮಾನ ಸೂಕ್ತವಾಗಿದೆ (26 - 32 C)';
    } else if ((temp >= WaterThresholds.tempMedLowMin &&
            temp < WaterThresholds.tempLowMin) ||
        (temp > WaterThresholds.tempLowMax &&
            temp <= WaterThresholds.tempMedHighMax)) {
      risk = WaterRiskLevel.medium;
      reasonEn = 'Temperature is sub-optimal (24 - 26 C or 32 - 34 C)';
      reasonKn = 'ತಾಪಮಾನ ಅಸಮತೋಲನದಲ್ಲಿದೆ (24 - 26 C ಅಥವಾ 32 - 34 C)';
    } else {
      risk = WaterRiskLevel.high;
      reasonEn = 'Temperature is extreme (< 24 C or > 34 C)';
      reasonKn = 'ತಾಪಮಾನ ತೀವ್ರವಾಗಿದೆ (< 24 C ಅಥವಾ > 34 C)';
    }

    return ParameterResult(
      key: 'temperature',
      nameEn: 'Temperature',
      nameKn: 'ತಾಪಮಾನ',
      value: temp,
      unit: '°C',
      risk: risk,
      reasonEn: reasonEn,
      reasonKn: reasonKn,
    );
  }

  static Map<String, String> _generateActionNote(
    WaterRiskLevel risk,
    List<ParameterResult> results,
  ) {
    if (risk == WaterRiskLevel.low) {
      return {
        'en':
            'Water conditions are stable. Continue regular feeding and daily monitoring.',
        'kn':
            'ನೀರಿನ ಗುಣಮಟ್ಟ ಸ್ಥಿರವಾಗಿದೆ. ಸಾಮಾನ್ಯ ಆಹಾರ ಮತ್ತು ದೈನಂದಿನ ಪರಿಶೀಲನೆ ಮುಂದುವರಿಸಿ.',
      };
    }

    // High risk specific actions
    final highParams =
        results.where((r) => r.risk == WaterRiskLevel.high).map((r) => r.key).toSet();

    if (highParams.contains('dissolvedOxygen')) {
      return {
        'en':
            'Urgent: Turn on paddle aerators immediately. Stop feeding until oxygen rises above 4.0 mg/L.',
        'kn':
            'ತುರ್ತು: ಕೂಡಲೇ ಏರೇಟರ್‌ಗಳನ್ನು ಆನ್ ಮಾಡಿ. ಆಮ್ಲಜನಕ 4.0 mg/L ತಲುಪುವವರೆಗೆ ಆಹಾರ ನೀಡುವುದನ್ನು ನಿಲ್ಲಿಸಿ.',
      };
    }

    if (highParams.contains('ammonia')) {
      return {
        'en':
            'Urgent: Reduce feed by 50% and exchange 10-20% pond water if clean source water is available.',
        'kn':
            'ತುರ್ತು: ಆಹಾರವನ್ನು 50% ಕಡಿಮೆ ಮಾಡಿ ಮತ್ತು ಸಾಧ್ಯವಾದರೆ 10-20% ಸ್ವಚ್ಛ ನೀರನ್ನು ಬದಲಾಯಿಸಿ.',
      };
    }

    if (highParams.contains('ph')) {
      return {
        'en':
            'Urgent: Apply agricultural lime (if acidic) or flush fresh water. Recheck in 4 hours.',
        'kn':
            'ತುರ್ತು: ಸುಣ್ಣವನ್ನು ಬಳಸಿ ಅಥವಾ ಹೊಸ ನೀರು ಸೇರಿಸಿ. 4 ಗಂಟೆಗಳ ನಂತರ ಮತ್ತೆ ಪರೀಕ್ಷಿಸಿ.',
      };
    }

    if (highParams.contains('temperature')) {
      return {
        'en':
            'Urgent: Check water depth and shade/aeration to moderate extreme pond temperatures.',
        'kn':
            'ತುರ್ತು: ನೀರಿನ ಆಳ ಹೆಚ್ಚಿಸಿ ಮತ್ತು ತಾಪಮಾನ ನಿಯಂತ್ರಿಸಲು ಏರೇಟರ್ ಬಳಸಿ.',
      };
    }

    // Medium risk actions
    return {
      'en':
          'Caution: One or more parameters require attention. Monitor aerators and retest in 6 hours.',
      'kn':
          'ಎಚ್ಚರಿಕೆ: ನೀರಿನ ಮಟ್ಟದಲ್ಲಿ ಏರುಪೇರಾಗಿದೆ. ಏರೇಟರ್ ಗಮನಿಸಿ ಮತ್ತು 6 ಗಂಟೆಗಳಲ್ಲಿ ಮತ್ತೆ ಪರೀಕ್ಷಿಸಿ.',
    };
  }
}
