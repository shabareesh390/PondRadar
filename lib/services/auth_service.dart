import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

enum UserRole { farmer, officer }

class AuthService extends ChangeNotifier {
  static const String _roleKey = 'pondradar_user_role';
  static const String _cachedUidKey = 'pondradar_cached_uid';

  UserRole? _role;
  String? _userId;
  bool _isLoading = true;

  UserRole? get role => _role;
  String get userId => _userId ?? 'offline_user';
  bool get isLoading => _isLoading;
  bool get isFarmer => _role == UserRole.farmer;
  bool get isOfficer => _role == UserRole.officer;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_roleKey);
    if (savedRole == 'farmer') {
      _role = UserRole.farmer;
    } else if (savedRole == 'officer') {
      _role = UserRole.officer;
    }

    _userId = prefs.getString(_cachedUidKey);
    if (_userId == null) {
      _userId = _generateFallbackId();
      await prefs.setString(_cachedUidKey, _userId!);
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (userCredential.user?.uid != null) {
        _userId = userCredential.user!.uid;
        await prefs.setString(_cachedUidKey, _userId!);
      }
    } catch (e) {
      // Keep fallback ID when offline or waiting for network
      debugPrint('Anonymous auth warning: $e, using cached ID $_userId');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectFarmerRole() async {
    _role = UserRole.farmer;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'farmer');
    notifyListeners();
  }

  Future<bool> verifyAndSelectOfficerRole(String pin) async {
    if (pin.trim() == AppConfig.officerPin) {
      _role = UserRole.officer;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, 'officer');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> switchRole() async {
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }

  String _generateFallbackId() {
    final rand = Random();
    return 'farmer_${rand.nextInt(900000) + 100000}';
  }
}
