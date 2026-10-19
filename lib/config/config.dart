import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration loaded from .env with fallback defaults.
class AppConfig {
  /// Demo PIN for fisheries officer authentication.
  static String get officerPin => dotenv.env['OFFICER_PIN'] ?? '8888';

  /// Google Maps API key.
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Gemini API key.
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY';

  /// Toggle Gemini advisory generation (falls back to local templates if disabled).
  static bool get enableGemini =>
      (dotenv.env['ENABLE_GEMINI'] ?? 'false').toLowerCase() == 'true';

  /// Firebase credentials from environment.
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'pondradar-4mt25cs';
  static String get firebaseWebApiKey =>
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';

  /// Outbreak clustering thresholds (evaluated client-side).
  static const double clusterRadiusKm = 3.0;
  static const int clusterTimeWindowHours = 48;
  static const int minIndependentReporters = 3;

  /// Grid size used to snap public report coordinates for farmer privacy (~500m).
  static const double publicLocationBlurGridMeters = 500.0;

  /// Center coordinates for Coastal Karnataka aquaculture hub (Udupi/Kundapura).
  static const double defaultLat = 13.3409;
  static const double defaultLng = 74.7421;

  /// Decision-support disclaimer shown across advisory cards.
  static const String disclaimerTextEn =
      'Decision-support aid, not a veterinary diagnosis.';
  static const String disclaimerTextKn =
      'ಇದು ನಿರ್ಧಾರ-ಬೆಂಬಲ ಸಾಧನವಾಗಿದ್ದು, ಪಶುವೈದ್ಯಕೀಯ ರೋಗನಿರ್ಣಯವಲ್ಲ.';

  /// Watermark banner text for demo/simulated records.
  static const String demoBannerTextEn = 'Simulated demo data';
  static const String demoBannerTextKn = 'ಅಣಕು ಡೆಮೊ ಮಾಹಿತಿ';
}
