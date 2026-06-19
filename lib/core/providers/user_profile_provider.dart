import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the user's profile (avatar, name, birth date, email, gender, activity
/// level) and biometric-lock setting, plus the app-load [ready] signal the
/// splash screen waits on. What remained after the former God-object provider
/// was split into focused providers (locale/units, goals, onboarding, reminders,
/// UI flags).
class UserProfileProvider extends ChangeNotifier {
  String? _profileImageBase64;
  String _userName = '';
  DateTime? _birthDate;
  String _userEmail = '';
  String _userGender = '';
  String _userActivityLevel = 'sedentary';

  // Legacy base64 blob in SharedPreferences. Still the storage on web (no
  // filesystem), and read once on mobile to migrate into [_imageFileName].
  static const String _imageKey = 'user_profile_image';
  // On mobile the image lives in this file under the documents directory.
  // The name is fixed so we never persist an absolute path (iOS rewrites the
  // container path between launches, which would invalidate a stored path).
  static const String _imageFileName = 'profile_photo.jpg';
  static const String _userNameKey = 'user_name';
  static const String _birthDateKey = 'user_birth_date';
  static const String _emailKey = 'user_email';
  static const String _genderKey = 'user_gender';
  static const String _activityLevelKey = 'user_activity_level';
  static const String _biometricKey = 'user_biometric_enabled';

  bool _isBiometricEnabled = false;
  bool _isReady = false;
  final Completer<void> _readyCompleter = Completer<void>();

  String? get profileImageBase64 => _profileImageBase64;
  String get userName => _userName;
  DateTime? get birthDate => _birthDate;
  String get userEmail => _userEmail;
  String get userGender => _userGender;
  String get userActivityLevel => _userActivityLevel;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isReady => _isReady;
  Future<void> get ready => _readyCompleter.future;

  UserProfileProvider() {
    _loadFromPrefs();
  }

  /// Re-reads all persisted preferences into memory and notifies listeners.
  /// Use after an external write to SharedPreferences (e.g. a restored backup)
  /// so the UI reflects the new values without restarting the app.
  Future<void> reload() => _loadFromPrefs();

  Future<void> setProfileImage(String? base64) async {
    _profileImageBase64 = base64;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      // No filesystem on web — keep the image as a base64 blob in prefs.
      if (base64 != null) {
        await prefs.setString(_imageKey, base64);
      } else {
        await prefs.remove(_imageKey);
      }
      return;
    }

    // Mobile: store the image as a file and keep it out of SharedPreferences,
    // which is loaded synchronously at startup and is size-limited on Android.
    final file = await _profileImageFile();
    if (base64 != null) {
      await file.writeAsBytes(base64Decode(base64), flush: true);
    } else if (await file.exists()) {
      await file.delete();
    }
    // Drop any legacy base64 blob that an older build may have left behind.
    await prefs.remove(_imageKey);
  }

  /// The on-disk location of the profile image on mobile platforms.
  Future<File> _profileImageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_imageFileName');
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  Future<void> updatePersonalInfo({
    required String name,
    required DateTime? dob,
    required String email,
    required String gender,
    required String activityLevel,
  }) async {
    _userName = name;
    _birthDate = dob;
    _userEmail = email;
    _userGender = gender;
    _userActivityLevel = activityLevel;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    if (dob != null) {
      await prefs.setString(_birthDateKey, dob.toIso8601String());
    } else {
      await prefs.remove(_birthDateKey);
    }
    await prefs.setString(_emailKey, email);
    await prefs.setString(_genderKey, gender);
    await prefs.setString(_activityLevelKey, activityLevel);
  }

  /// Resolves the in-memory [_profileImageBase64] from persistent storage.
  /// On web it reads the base64 blob from prefs. On mobile it reads the image
  /// file, migrating a legacy base64 blob into a file on first run.
  Future<void> _loadProfileImage(SharedPreferences prefs) async {
    if (kIsWeb) {
      _profileImageBase64 = prefs.getString(_imageKey);
      return;
    }

    final file = await _profileImageFile();
    if (await file.exists()) {
      _profileImageBase64 = base64Encode(await file.readAsBytes());
      return;
    }

    // One-time migration: an older build stored the base64 directly in prefs.
    final legacy = prefs.getString(_imageKey);
    if (legacy != null && legacy.isNotEmpty) {
      try {
        await file.writeAsBytes(base64Decode(legacy), flush: true);
        _profileImageBase64 = legacy;
      } catch (_) {
        _profileImageBase64 = null;
      }
      await prefs.remove(_imageKey);
    } else {
      _profileImageBase64 = null;
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Image (platform-aware, migrates legacy base64 on mobile)
    await _loadProfileImage(prefs);

    // Load Personal Info
    _userName = prefs.getString(_userNameKey) ?? '';
    final String? dobString = prefs.getString(_birthDateKey);
    if (dobString != null) {
      _birthDate = DateTime.tryParse(dobString);
    }
    _userEmail = prefs.getString(_emailKey) ?? '';
    _userGender = prefs.getString(_genderKey) ?? '';
    _userActivityLevel = prefs.getString(_activityLevelKey) ?? 'sedentary';

    _isBiometricEnabled = prefs.getBool(_biometricKey) ?? false;

    _isReady = true;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    notifyListeners();
  }
}

