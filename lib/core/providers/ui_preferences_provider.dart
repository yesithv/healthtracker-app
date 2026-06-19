import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI-only flags, currently the dismissed state of the record-screen info
/// banners. Extracted from the former God-object PreferencesProvider so
/// dismissing a banner only rebuilds the screen that shows it.
class UIPreferencesProvider extends ChangeNotifier {
  static const String _infoAnthroDismissedKey = 'info_anthro_dismissed';
  static const String _infoVitalsDismissedKey = 'info_vitals_dismissed';
  static const String _infoBodyCompDismissedKey = 'info_body_comp_dismissed';

  bool _isAnthropoInfoDismissed = false;
  bool _isVitalInfoDismissed = false;
  bool _isBodyCompInfoDismissed = false;

  bool get isAnthropoInfoDismissed => _isAnthropoInfoDismissed;
  bool get isVitalInfoDismissed => _isVitalInfoDismissed;
  bool get isBodyCompInfoDismissed => _isBodyCompInfoDismissed;

  UIPreferencesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isAnthropoInfoDismissed = prefs.getBool(_infoAnthroDismissedKey) ?? false;
    _isVitalInfoDismissed = prefs.getBool(_infoVitalsDismissedKey) ?? false;
    _isBodyCompInfoDismissed = prefs.getBool(_infoBodyCompDismissedKey) ?? false;
    notifyListeners();
  }

  Future<void> dismissAnthropoInfo() async {
    _isAnthropoInfoDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_infoAnthroDismissedKey, true);
    notifyListeners();
  }

  Future<void> dismissVitalInfo() async {
    _isVitalInfoDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_infoVitalsDismissedKey, true);
    notifyListeners();
  }

  Future<void> dismissBodyCompInfo() async {
    _isBodyCompInfoDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_infoBodyCompDismissedKey, true);
    notifyListeners();
  }
}
