import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, kn }

class LanguageNotifier extends ChangeNotifier {
  static const String _prefKey = 'selected_language';
  AppLanguage _currentLanguage = AppLanguage.en;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isKannada => _currentLanguage == AppLanguage.kn;

  LanguageNotifier() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == 'kn') {
      _currentLanguage = AppLanguage.kn;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang == AppLanguage.kn ? 'kn' : 'en');
  }

  void toggleLanguage() {
    setLanguage(
      _currentLanguage == AppLanguage.en ? AppLanguage.kn : AppLanguage.en,
    );
  }
}

class AppStrings {
  static String get(String key, AppLanguage lang) {
    final map = _strings[key];
    if (map == null) return key;
    return map[lang] ?? map[AppLanguage.en] ?? key;
  }

  static const Map<String, Map<AppLanguage, String>> _strings = {
    // General
    'appName': {
      AppLanguage.en: 'PondRadar',
      AppLanguage.kn: 'ಪಾಂಡ್‌ರಾಡಾರ್',
    },
    'disclaimer': {
      AppLanguage.en: 'Decision-support aid, not a veterinary diagnosis.',
      AppLanguage.kn: 'ಇದು ನಿರ್ಧಾರ-ಬೆಂಬಲ ಸಾಧನವಾಗಿದ್ದು, ಪಶುವೈದ್ಯಕೀಯ ರೋಗನಿರ್ಣಯವಲ್ಲ.',
    },
    'simulatedDataBanner': {
      AppLanguage.en: 'Simulated demo data',
      AppLanguage.kn: 'ಅಣಕು ಡೆಮೊ ಮಾಹಿತಿ',
    },
    'offlineBanner': {
      AppLanguage.en:
          'You are offline. Reports will send when you reconnect.',
      AppLanguage.kn:
          'ನೀವು ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿದ್ದೀರಿ. ಮರುಸಂಪರ್ಕಗೊಂಡಾಗ ವರದಿಗಳು ಕಳುಹಿಸಲ್ಪಡುತ್ತವೆ.',
    },
    'loading': {
      AppLanguage.en: 'Loading...',
      AppLanguage.kn: 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
    },
    'retry': {
      AppLanguage.en: 'Retry',
      AppLanguage.kn: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    },
    'cancel': {
      AppLanguage.en: 'Cancel',
      AppLanguage.kn: 'ರದ್ದುಮಾಡಿ',
    },
    'save': {
      AppLanguage.en: 'Save',
      AppLanguage.kn: 'ಉಳಿಸಿ',
    },
    'delete': {
      AppLanguage.en: 'Delete',
      AppLanguage.kn: 'ಅಳಿಸಿ',
    },

    // Role selection
    'selectRole': {
      AppLanguage.en: 'Select your role',
      AppLanguage.kn: 'ನಿಮ್ಮ ಪಾತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    },
    'farmerRole': {
      AppLanguage.en: 'Aquaculture Farmer',
      AppLanguage.kn: 'ಜಲಚರ ಕೃಷಿಕ (ರೈತ)',
    },
    'farmerDesc': {
      AppLanguage.en: 'Monitor pond water quality and receive disease alerts',
      AppLanguage.kn: 'ಕೊಳದ ನೀರಿನ ಗುಣಮಟ್ಟ ಪರಿಶೀಲಿಸಿ ಮತ್ತು ರೋಗ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಪಡೆಯಿರಿ',
    },
    'officerRole': {
      AppLanguage.en: 'Fisheries Officer',
      AppLanguage.kn: 'ಮೀನುಗಾರಿಕಾ ಅಧಿಕಾರಿ',
    },
    'officerDesc': {
      AppLanguage.en: 'Monitor regional outbreaks and track farm reports',
      AppLanguage.kn: 'ಪ್ರಾದೇಶಿಕ ರೋಗ ಉಲ್ಬಣಗಳನ್ನು ಮತ್ತು ವರದಿಗಳನ್ನು ಮೇಲ್ವಿಚಾರಣೆ ಮಾಡಿ',
    },
    'enterPin': {
      AppLanguage.en: 'Enter officer PIN',
      AppLanguage.kn: 'ಅಧಿಕಾರಿ ಪಿನ್ ನಮೂದಿಸಿ',
    },
    'submitPin': {
      AppLanguage.en: 'Verify PIN',
      AppLanguage.kn: 'ಪಿನ್ ಪರಿಶೀಲಿಸಿ',
    },
    'invalidPin': {
      AppLanguage.en: 'Incorrect PIN. Please try again.',
      AppLanguage.kn: 'ತಪ್ಪಾದ ಪಿನ್. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    },

    // Navigation
    'navHome': {
      AppLanguage.en: 'Home',
      AppLanguage.kn: 'ಮುಖಪುಟ',
    },
    'navAlerts': {
      AppLanguage.en: 'Alerts',
      AppLanguage.kn: 'ಎಚ್ಚರಿಕೆಗಳು',
    },
    'navSettings': {
      AppLanguage.en: 'Settings',
      AppLanguage.kn: 'ಸೆಟ್ಟಿಂಗ್ಸ್',
    },

    // Farmer Home
    'myPonds': {
      AppLanguage.en: 'My ponds',
      AppLanguage.kn: 'ನನ್ನ ಕೊಳಗಳು',
    },
    'noPonds': {
      AppLanguage.en: 'No ponds registered yet.',
      AppLanguage.kn: 'ಇನ್ನೂ ಯಾವುದೇ ಕೊಳಗಳು ನೋಂದಾಯಿಸಲ್ಪಟ್ಟಿಲ್ಲ.',
    },
    'addFirstPond': {
      AppLanguage.en: 'Add your first pond',
      AppLanguage.kn: 'ಮೊದಲ ಕೊಳವನ್ನು ಸೇರಿಸಿ',
    },
    'checkWater': {
      AppLanguage.en: 'Check water',
      AppLanguage.kn: 'ನೀರು ಪರಿಶೀಲಿಸಿ',
    },
    'reportProblem': {
      AppLanguage.en: 'Report problem',
      AppLanguage.kn: 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ',
    },
    'lastStatus': {
      AppLanguage.en: 'Last status',
      AppLanguage.kn: 'ಕೊನೆಯ ಸ್ಥಿತಿ',
    },
    'testedOn': {
      AppLanguage.en: 'Tested on',
      AppLanguage.kn: 'ಪರೀಕ್ಷಿಸಿದ ದಿನಾಂಕ',
    },

    // Add pond
    'addPondTitle': {
      AppLanguage.en: 'Add pond',
      AppLanguage.kn: 'ಕೊಳ ಸೇರಿಸಿ',
    },
    'pondName': {
      AppLanguage.en: 'Pond name',
      AppLanguage.kn: 'ಕೊಳದ ಹೆಸರು',
    },
    'pondNameHint': {
      AppLanguage.en: 'e.g. Pond 1 - Udupi',
      AppLanguage.kn: 'ಉದಾ: ಕೊಳ 1 - ಉಡುಪಿ',
    },
    'species': {
      AppLanguage.en: 'Species',
      AppLanguage.kn: 'ತಳಿ',
    },
    'speciesShrimp': {
      AppLanguage.en: 'Shrimp (Vannamei)',
      AppLanguage.kn: 'ಸೀಗಡಿ (ವನ್ನಾಮಿ)',
    },
    'speciesFish': {
      AppLanguage.en: 'Fish',
      AppLanguage.kn: 'ಮೀನು',
    },
    'location': {
      AppLanguage.en: 'Pond location',
      AppLanguage.kn: 'ಕೊಳದ ಸ್ಥಳ',
    },
    'useCurrentLocation': {
      AppLanguage.en: 'Use current GPS location',
      AppLanguage.kn: 'ಪ್ರಸ್ತುತ ಜಿಪಿಎಸ್ ಸ್ಥಳ ಬಳಸಿ',
    },
    'fetchingLocation': {
      AppLanguage.en: 'Fetching location...',
      AppLanguage.kn: 'ಸ್ಥಳ ಪಡೆಯಲಾಗುತ್ತಿದೆ...',
    },

    // Water check
    'waterCheckTitle': {
      AppLanguage.en: 'Pond water check',
      AppLanguage.kn: 'ಕೊಳದ ನೀರಿನ ಪರಿಶೀಲನೆ',
    },
    'phLabel': {
      AppLanguage.en: 'pH level',
      AppLanguage.kn: 'ಪಿಹೆಚ್ ಮಟ್ಟ',
    },
    'phValidation': {
      AppLanguage.en: 'Enter a pH between 0 and 14',
      AppLanguage.kn: '0 ಮತ್ತು 14 ನಡುವಿನ ಪಿಹೆಚ್ ನಮೂದಿಸಿ',
    },
    'doLabel': {
      AppLanguage.en: 'Dissolved oxygen',
      AppLanguage.kn: 'ಕರಗಿದ ಆಮ್ಲಜನಕ',
    },
    'doValidation': {
      AppLanguage.en: 'Enter dissolved oxygen in mg/L',
      AppLanguage.kn: 'ಕರಗಿದ ಆಮ್ಲಜನಕವನ್ನು mg/L ನಲ್ಲಿ ನಮೂದಿಸಿ',
    },
    'ammoniaLabel': {
      AppLanguage.en: 'Ammonia',
      AppLanguage.kn: 'ಅಮೋನಿಯಾ',
    },
    'ammoniaValidation': {
      AppLanguage.en: 'Enter ammonia in mg/L',
      AppLanguage.kn: 'ಅಮೋನಿಯಾವನ್ನು mg/L ನಲ್ಲಿ ನಮೂದಿಸಿ',
    },
    'temperatureLabel': {
      AppLanguage.en: 'Temperature',
      AppLanguage.kn: 'ತಾಪಮಾನ',
    },
    'temperatureValidation': {
      AppLanguage.en: 'Enter temperature in °C',
      AppLanguage.kn: 'ತಾಪಮಾನವನ್ನು °C ನಲ್ಲಿ ನಮೂದಿಸಿ',
    },
    'evaluateRisk': {
      AppLanguage.en: 'Evaluate water risk',
      AppLanguage.kn: 'ಅಪಾಯ ಮಟ್ಟ ಮೌಲ್ಯಮಾಪನ ಮಾಡಿ',
    },
    'riskAssessment': {
      AppLanguage.en: 'Risk assessment result',
      AppLanguage.kn: 'ಅಪಾಯ ಮೌಲ್ಯಮಾಪನ ಫಲಿತಾಂಶ',
    },
    'actionRequired': {
      AppLanguage.en: 'Recommended action',
      AppLanguage.kn: 'ಶಿಫಾರಸು ಮಾಡಿದ ಕ್ರಮ',
    },
    'trendHistory': {
      AppLanguage.en: 'Previous readings',
      AppLanguage.kn: 'ಹಿಂದಿನ ಅಳತೆಗಳು',
    },

    // Report problem
    'reportTitle': {
      AppLanguage.en: 'Report pond symptoms',
      AppLanguage.kn: 'ಕೊಳದ ರೋಗಲಕ್ಷಣ ವರದಿ',
    },
    'selectSymptoms': {
      AppLanguage.en: 'Select symptoms observed',
      AppLanguage.kn: 'ಕಂಡುಬಂದ ರೋಗಲಕ್ಷಣಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    },
    'symptomLethargy': {
      AppLanguage.en: 'Lethargy',
      AppLanguage.kn: 'ನಿಶ್ಚೇಷ್ಟತೆ (ಚಟುವಟಿಕೆ ಕಡಿಮೆ)',
    },
    'symptomSurfaceGasping': {
      AppLanguage.en: 'Surface gasping',
      AppLanguage.kn: 'ಮೇಲ್ಮೈಯಲ್ಲಿ ಉಸಿರಾಟ',
    },
    'symptomWhiteSpots': {
      AppLanguage.en: 'White spots',
      AppLanguage.kn: 'ಬಿಳಿ ಚುಕ್ಕೆಗಳು',
    },
    'symptomDiscolouredWater': {
      AppLanguage.en: 'Discoloured water',
      AppLanguage.kn: 'ಬಣ್ಣ ಬದಲಾದ ನೀರು',
    },
    'symptomSuddenDeaths': {
      AppLanguage.en: 'Sudden deaths',
      AppLanguage.kn: 'ಧಿಡೀರ್ ಸಾವುಗಳು',
    },
    'symptomReducedFeeding': {
      AppLanguage.en: 'Reduced feeding',
      AppLanguage.kn: 'ಆಹಾರ ಸೇವನೆ ಇಳಿಕೆ',
    },
    'optionalPhoto': {
      AppLanguage.en: 'Pond photo (optional)',
      AppLanguage.kn: 'ಕೊಳದ ಫೋಟೋ (ಐಚ್ಛಿಕ)',
    },
    'submitReport': {
      AppLanguage.en: 'Submit report',
      AppLanguage.kn: 'ವರದಿ ಸಲ್ಲಿಸಿ',
    },
    'reportSubmitted': {
      AppLanguage.en: 'Report recorded successfully.',
      AppLanguage.kn: 'ವರದಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ದಾಖಲಿಸಲಾಗಿದೆ.',
    },

    // Alerts
    'alertsTitle': {
      AppLanguage.en: 'Community Outbreak Radar',
      AppLanguage.kn: 'ಸಮುದಾಯ ರೋಗ ಎಚ್ಚರಿಕೆ ರಾಡಾರ್',
    },
    'noAlerts': {
      AppLanguage.en: 'No outbreak alerts near your ponds.',
      AppLanguage.kn: 'ನಿಮ್ಮ ಕೊಳಗಳ ಸಮೀಪ ಯಾವುದೇ ರೋಗ ಉಲ್ಬಣ ಎಚ್ಚರಿಕೆಗಳಿಲ್ಲ.',
    },
    'nearbyAlert': {
      AppLanguage.en: 'Outbreak cluster detected nearby',
      AppLanguage.kn: 'ಸಮೀಪದಲ್ಲಿ ರೋಗ ಉಲ್ಬಣ ಪತ್ತೆಯಾಗಿದೆ',
    },
    'distanceFromPond': {
      AppLanguage.en: 'Distance from your pond',
      AppLanguage.kn: 'ನಿಮ್ಮ ಕೊಳದಿಂದ ದೂರ',
    },

    // Officer
    'officerDashboard': {
      AppLanguage.en: 'Officer Dashboard',
      AppLanguage.kn: 'ಅಧಿಕಾರಿ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
    },
    'tabMap': {
      AppLanguage.en: 'Map view',
      AppLanguage.kn: 'ನಕ್ಷೆ ನೋಟ',
    },
    'tabReports': {
      AppLanguage.en: 'Reports log',
      AppLanguage.kn: 'ವರದಿಗಳ ದಾಖಲೆ',
    },
    'tabAlerts': {
      AppLanguage.en: 'Active clusters',
      AppLanguage.kn: 'ಸಕ್ರಿಯ ಕ್ಲಸ್ಟರ್‌ಗಳು',
    },
    'loadDemoData': {
      AppLanguage.en: 'Load demo data (40 reports)',
      AppLanguage.kn: 'ಡೆಮೊ ಮಾಹಿತಿ ಲೋಡ್ ಮಾಡಿ',
    },
    'simulateOutbreak': {
      AppLanguage.en: 'Simulate outbreak (3 reports)',
      AppLanguage.kn: 'ರೋಗ ಉಲ್ಬಣವನ್ನು ಅನುಕರಿಸಿ',
    },
    'switchRole': {
      AppLanguage.en: 'Switch role',
      AppLanguage.kn: 'ಪಾತ್ರ ಬದಲಾಯಿಸಿ',
    },
    'clearDemoData': {
      AppLanguage.en: 'Clear demo data',
      AppLanguage.kn: 'ಡೆಮೊ ಮಾಹಿತಿ ಅಳಿಸಿ',
    },
  };
}
