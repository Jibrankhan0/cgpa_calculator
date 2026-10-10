import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppData extends ChangeNotifier {
  bool _isDark = false;
  bool _hasSeenOnboarding = false;
  String _userName = '';
  String _userAvatar = 'assets/B1-removebg-preview.png';

  Timer? _saveTimer;

  bool get isDark => _isDark;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get userName => _userName;
  String get userAvatar => _userAvatar;

  static const List<String> avatars = [
    'assets/B1-removebg-preview.png',
    'assets/B2-removebg-preview.png',
    'assets/B4-removebg-preview.png',
    'assets/B5-removebg-preview.png',
    'assets/G1-removebg-preview.png',
    'assets/G2-removebg-preview (1).png',
    'assets/vecteezy_3d-muslim-woman-avatar_60236525.png',
    'assets/G5-removebg-preview.png',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('mckru_dark2') ?? false;
    _hasSeenOnboarding = prefs.getBool('mckru_onboarded2') ?? false;
    _userName = prefs.getString('mckru_name') ?? '';
    _userAvatar = prefs.getString('mckru_avatar') ?? 'assets/B1-removebg-preview.png';
    notifyListeners();
  }

  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mckru_dark2', _isDark);
    await prefs.setBool('mckru_onboarded2', _hasSeenOnboarding);
    await prefs.setString('mckru_name', _userName);
    await prefs.setString('mckru_avatar', _userAvatar);
  }

  void toggleDark() {
    _isDark = !_isDark;
    _debounceSave();
    notifyListeners();
  }

  void finishOnboarding(String name, String avatar) {
    _userName = name;
    _userAvatar = avatar;
    _hasSeenOnboarding = true;
    _debounceSave();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    _debounceSave();
    notifyListeners();
  }

  void setUserAvatar(String avatar) {
    _userAvatar = avatar;
    _debounceSave();
    notifyListeners();
  }

  void clearAll() {
    // Only clears user prefs, not sheet data (handled by independent providers)
    _isDark = false;
    _hasSeenOnboarding = false;
    _userName = '';
    _userAvatar = 'assets/B1-removebg-preview.png';
    _debounceSave();
    notifyListeners();
  }

  void resetAll() {
    _isDark = false;
    _hasSeenOnboarding = false;
    _userName = '';
    _userAvatar = 'assets/B1-removebg-preview.png';
    _debounceSave();
    notifyListeners();
  }
}