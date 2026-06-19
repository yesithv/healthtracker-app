import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed the first-run onboarding wizard.
/// Extracted from the former God-object PreferencesProvider. Exposes its own
/// [ready] future so the splash screen can gate navigation on it being loaded.
class OnboardingProvider extends ChangeNotifier {
  static const String _onboardingKey = 'onboarding_complete';

  bool _isComplete = false;
  bool _isReady = false;
  final Completer<void> _readyCompleter = Completer<void>();

  bool get isComplete => _isComplete;
  bool get isReady => _isReady;
  Future<void> get ready => _readyCompleter.future;

  OnboardingProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isComplete = prefs.getBool(_onboardingKey) ?? false;
    _isReady = true;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    notifyListeners();
  }

  Future<void> setComplete() async {
    _isComplete = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
