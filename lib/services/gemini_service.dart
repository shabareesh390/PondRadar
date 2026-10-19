import 'package:flutter/foundation.dart';
import '../config/config.dart';

class GeminiPhotoTriageResult {
  final String observationEn;
  final String observationKn;
  final String confidenceNotice;

  const GeminiPhotoTriageResult({
    required this.observationEn,
    required this.observationKn,
    this.confidenceNotice = 'Low confidence, not a diagnosis.',
  });
}

/// Advisory triage service (behind feature flag [AppConfig.enableGemini], default OFF).
/// Uses pre-written, expert-curated Kannada/English templates by default.
class GeminiService {
  /// Gemini API key from environment.
  static String get geminiApiKey => AppConfig.geminiApiKey;

  /// Returns triage guidance from observed symptoms or photos.
  static Future<GeminiPhotoTriageResult> triageSymptoms(
    List<String> symptoms,
  ) async {
    if (!AppConfig.enableGemini) {
      // Use local expert template when AI flag is disabled
      return _getCuratedFallback(symptoms);
    }

    try {
      // Live Gemini vision/text API call can be plugged in here when enabled
      return _getCuratedFallback(symptoms);
    } catch (e) {
      debugPrint('Gemini triage fallback: $e');
      return _getCuratedFallback(symptoms);
    }
  }

  /// Formats a localized Kannada alert banner for farmer notifications.
  static String formatKannadaAlert({
    required String pondName,
    required double distanceKm,
    required int reportCount,
    required List<String> symptoms,
  }) {
    // Template fallback for Kannada alerts
    final symptomListStr = symptoms.map((s) => _kannadaSymptom(s)).join(', ');
    return 'ಎಚ್ಚರಿಕೆ: ನಿಮ್ಮ "$pondName" ಕೊಳದಿಂದ ${distanceKm.toStringAsFixed(1)} ಕಿ.ಮೀ ದೂರದಲ್ಲಿ ರೋಗ ಲಕ್ಷಣಗಳ ಕ್ಲಸ್ಟರ್ ಪತ್ತೆಯಾಗಿದೆ ($reportCount ರೈತರು $symptomListStr ವರದಿ ಮಾಡಿದ್ದಾರೆ). ಮುನ್ನೆಚ್ಚರಿಕೆ ವಹಿಸಿ.';
  }

  static GeminiPhotoTriageResult _getCuratedFallback(List<String> symptoms) {
    if (symptoms.contains('white_spots')) {
      return const GeminiPhotoTriageResult(
        observationEn:
            'Possible White Spot Syndrome Virus (WSSV) indicator. Isolate pond and restrict water exchange.',
        observationKn:
            'ಬಿಳಿ ಚುಕ್ಕೆ ರೋಗದ (WSSV) ಲಕ್ಷಣವಾಗಿರಬಹುದು. ಕೊಳದ ನೀರನ್ನು ಬದಲಾಯಿಸುವುದನ್ನು ತಕ್ಷಣ ನಿಲ್ಲಿಸಿ.',
      );
    }

    if (symptoms.contains('surface_gasping') ||
        symptoms.contains('discoloured_water')) {
      return const GeminiPhotoTriageResult(
        observationEn:
            'Severe hypoxia or algal bloom crash indicated. Run all mechanical paddle aerators immediately.',
        observationKn:
            'ಆಮ್ಲಜನಕದ ಕೊರತೆ ಅಥವಾ ಪಾಚಿ ನಾಶದ ಲಕ್ಷಣ. ಕೂಡಲೇ ಎಲ್ಲಾ ಏರೇಟರ್‌ಗಳನ್ನು ಆನ್ ಮಾಡಿ.',
      );
    }

    return const GeminiPhotoTriageResult(
      observationEn:
          'General aquaculture stress symptoms noted. Check water pH, dissolved oxygen, and ammonia levels.',
      observationKn:
          'ಜಲಚರಗಳ ಒತ್ತಡದ ಲಕ್ಷಣ ಕಂಡುಬಂದಿದೆ. ನೀರಿನ ಪಿಹೆಚ್, ಆಮ್ಲಜನಕ ಮತ್ತು ಅಮೋನಿಯಾ ಪರಿಶೀಲಿಸಿ.',
    );
  }

  static String _kannadaSymptom(String key) {
    switch (key) {
      case 'white_spots':
        return 'ಬಿಳಿ ಚುಕ್ಕೆ';
      case 'surface_gasping':
        return 'ಮೇಲ್ಮೈ ಉಸಿರಾಟ';
      case 'sudden_deaths':
        return 'ಧಿಡೀರ್ ಸಾವು';
      case 'lethargy':
        return 'ನಿಶ್ಚೇಷ್ಟತೆ';
      case 'discoloured_water':
        return 'ನೀರಿನ ಬಣ್ಣ ಬದಲಾವಣೆ';
      case 'reduced_feeding':
        return 'ಆಹಾರ ಸೇವನೆ ಇಳಿಕೆ';
      default:
        return key;
    }
  }
}
