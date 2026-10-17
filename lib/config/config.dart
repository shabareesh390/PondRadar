import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global app configuration for PondRadar loaded from .env.
class AppConfig {
  /// Demo PIN for Officer authentication
  static String get officerPin => dotenv.env['OFFICER_PIN'] ?? '8888';

  /// Google Maps API Key
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Gemini AI API Key
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY';

  /// Gemini AI feature flag (default: OFF, uses pre-written Kannada templates)
  static bool get enableGemini =>
      (dotenv.env['ENABLE_GEMINI'] ?? 'false').toLowerCase() == 'true';

  /// Firebase credentials from .env
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'pondradar-4mt25cs';
  static String get firebaseWebApiKey =>
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';

  /// Outbreak clustering parameters (deterministic client-side)
  static const double clusterRadiusKm = 3.0;
  static const int clusterTimeWindowHours = 48;
  static const int minIndependentReporters = 3;

  /// Privacy: public report coordinate snapping grid size in meters (~500m)
  static const double publicLocationBlurGridMeters = 500.0;

  /// Center coordinate for Coastal Karnataka (Udupi / Kundapura aquaculture hub)
  static const double defaultLat = 13.3409;
  static const double defaultLng = 74.7421;

  /// Mandatory legal/decision support disclaimer
  static const String disclaimerTextEn =
      'Decision-support aid, not a veterinary diagnosis.';
  static const String disclaimerTextKn =
      'ಇದು ನಿರ್ಧಾರ-ಬೆಂಬಲ ಸಾಧನವಾಗಿದ್ದು, ಪಶುವೈದ್ಯಕೀಯ ರೋಗನಿರ್ಣಯವಲ್ಲ.';

  /// Simulated demo data banner text
  static const String demoBannerTextEn = 'Simulated demo data';
  static const String demoBannerTextKn = 'ಅಣಕು ಡೆಮೊ ಮಾಹಿತಿ';
}
