/// Risk evaluation thresholds and definitions for aquaculture water quality.
/// All thresholds are stored as data with source references.
library;

enum WaterRiskLevel {
  low,
  medium,
  high;

  String get labelEn {
    switch (this) {
      case WaterRiskLevel.low:
        return 'Low risk';
      case WaterRiskLevel.medium:
        return 'Medium risk';
      case WaterRiskLevel.high:
        return 'High risk';
    }
  }

  String get labelKn {
    switch (this) {
      case WaterRiskLevel.low:
        return 'ಕಡಿಮೆ ಅಪಾಯ';
      case WaterRiskLevel.medium:
        return 'ಮಧ್ಯಮ ಅಪಾಯ';
      case WaterRiskLevel.high:
        return 'ಹೆಚ್ಚಿನ ಅಪಾಯ';
    }
  }

  int get severity {
    switch (this) {
      case WaterRiskLevel.low:
        return 1;
      case WaterRiskLevel.medium:
        return 2;
      case WaterRiskLevel.high:
        return 3;
    }
  }
}

class ParameterThresholdRule {
  final String key;
  final String nameEn;
  final String nameKn;
  final String unit;
  final String sourceComment;

  const ParameterThresholdRule({
    required this.key,
    required this.nameEn,
    required this.nameKn,
    required this.unit,
    required this.sourceComment,
  });
}

class WaterThresholds {
  // SOURCE: FAO shrimp culture manual, Water Quality Management;
  // values outside 7.5-9.0 need review: TO VERIFY.
  static const String phSource =
      'FAO shrimp culture manual, Water Quality Management; values outside 7.5-9.0 need review: TO VERIFY.';
  static const double phLowMin = 7.5;
  static const double phLowMax = 8.5;
  static const double phMedLowMin = 7.0;
  static const double phMedHighMax = 9.5;

  // SOURCE: FAO shrimp water management, Dissolved Oxygen guidelines: TO VERIFY.
  static const String doSource =
      'FAO shrimp culture manual - Dissolved oxygen: Low >= 4 mg/L; Medium 3-4; High < 3: TO VERIFY.';
  static const double doLowMin = 4.0;
  static const double doMedMin = 3.0;

  // SOURCE: Central Institute of Brackishwater Aquaculture (CIBA) / FAO guidelines: TO VERIFY.
  static const String ammoniaSource =
      'CIBA / FAO shrimp guidelines - Ammonia: Low <= 0.1 mg/L; Medium 0.1-0.3; High > 0.3: TO VERIFY.';
  static const double ammoniaLowMax = 0.1;
  static const double ammoniaMedMax = 0.3;

  // SOURCE: Coastal Karnataka ambient shrimp pond range placeholder: TO VERIFY.
  static const String tempSource =
      'Clearly marked placeholder ranges for coastal Karnataka ambient waters: TO VERIFY.';
  static const double tempLowMin = 26.0;
  static const double tempLowMax = 32.0;
  static const double tempMedLowMin = 24.0;
  static const double tempMedHighMax = 34.0;
}

class ParameterResult {
  final String key;
  final String nameEn;
  final String nameKn;
  final double value;
  final String unit;
  final WaterRiskLevel risk;
  final String reasonEn;
  final String reasonKn;

  const ParameterResult({
    required this.key,
    required this.nameEn,
    required this.nameKn,
    required this.value,
    required this.unit,
    required this.risk,
    required this.reasonEn,
    required this.reasonKn,
  });
}

class WaterRiskEvaluation {
  final WaterRiskLevel overallRisk;
  final List<ParameterResult> parameterResults;
  final String actionNoteEn;
  final String actionNoteKn;
  final DateTime evaluatedAt;

  const WaterRiskEvaluation({
    required this.overallRisk,
    required this.parameterResults,
    required this.actionNoteEn,
    required this.actionNoteKn,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'overallRisk': overallRisk.name,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'actionNoteEn': actionNoteEn,
      'actionNoteKn': actionNoteKn,
      'parameters': parameterResults
          .map((p) => {
                'key': p.key,
                'value': p.value,
                'unit': p.unit,
                'risk': p.risk.name,
                'reasonEn': p.reasonEn,
                'reasonKn': p.reasonKn,
              })
          .toList(),
    };
  }

  factory WaterRiskEvaluation.fromMap(Map<String, dynamic> map) {
    final overallRiskStr = map['overallRisk'] as String? ?? 'low';
    final riskLevel = WaterRiskLevel.values.firstWhere(
      (e) => e.name == overallRiskStr,
      orElse: () => WaterRiskLevel.low,
    );
    final paramsList = (map['parameters'] as List<dynamic>? ?? [])
        .map((item) {
          final pMap = item as Map<String, dynamic>;
          final pRisk = WaterRiskLevel.values.firstWhere(
            (e) => e.name == (pMap['risk'] as String? ?? 'low'),
            orElse: () => WaterRiskLevel.low,
          );
          return ParameterResult(
            key: pMap['key'] as String? ?? '',
            nameEn: _getParamNameEn(pMap['key'] as String? ?? ''),
            nameKn: _getParamNameKn(pMap['key'] as String? ?? ''),
            value: (pMap['value'] as num? ?? 0).toDouble(),
            unit: pMap['unit'] as String? ?? '',
            risk: pRisk,
            reasonEn: pMap['reasonEn'] as String? ?? '',
            reasonKn: pMap['reasonKn'] as String? ?? '',
          );
        })
        .toList();

    return WaterRiskEvaluation(
      overallRisk: riskLevel,
      parameterResults: paramsList,
      actionNoteEn: map['actionNoteEn'] as String? ?? '',
      actionNoteKn: map['actionNoteKn'] as String? ?? '',
      evaluatedAt: DateTime.tryParse(map['evaluatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String _getParamNameEn(String key) {
    switch (key) {
      case 'ph':
        return 'pH';
      case 'ammonia':
        return 'Ammonia';
      case 'dissolvedOxygen':
        return 'Dissolved Oxygen';
      case 'temperature':
        return 'Temperature';
      default:
        return key;
    }
  }

  static String _getParamNameKn(String key) {
    switch (key) {
      case 'ph':
        return 'ಪಿಹೆಚ್ (pH)';
      case 'ammonia':
        return 'ಅಮೋನಿಯಾ';
      case 'dissolvedOxygen':
        return 'ಕರಗಿದ ಆಮ್ಲಜನಕ';
      case 'temperature':
        return 'ತಾಪಮಾನ';
      default:
        return key;
    }
  }
}
