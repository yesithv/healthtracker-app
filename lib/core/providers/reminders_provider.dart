import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';

/// Owns the user's reminder list. Extracted from the former God-object
/// PreferencesProvider so screens that only care about reminders rebuild
/// independently from unrelated preference changes.
class RemindersProvider extends ChangeNotifier {
  static const String _remindersKey = 'user_reminders';

  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;

  RemindersProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString(_remindersKey);
    if (remindersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        _reminders = decoded
            .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _reminders = _defaultReminders();
      }
    } else {
      _reminders = _defaultReminders();
    }
    notifyListeners();
  }

  Future<void> updateReminders(List<Reminder> newReminders) async {
    _reminders = newReminders;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _reminders.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_remindersKey, encoded);
  }

  /// Re-reads reminders from storage (e.g. after a restored backup).
  Future<void> reload() => _load();

  /// Borra los recordatorios del usuario y vuelve a los de por defecto (al cerrar
  /// sesión / cambiar de paciente).
  Future<void> clear() async {
    _reminders = _defaultReminders();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
  }

  List<Reminder> _defaultReminders() {
    return const [
      Reminder(
        id: 'r1',
        translationKey: 'reminderVitals',
        time: TimeOfDay(hour: 8, minute: 0),
        isEnabled: false,
      ),
      Reminder(
        id: 'r2',
        translationKey: 'reminderMeds',
        time: TimeOfDay(hour: 12, minute: 0),
        isEnabled: false,
      ),
      Reminder(
        id: 'r3',
        translationKey: 'reminderWorkout',
        time: TimeOfDay(hour: 17, minute: 30),
        isEnabled: false,
      ),
      Reminder(
        id: 'r4',
        translationKey: 'reminderWater',
        time: TimeOfDay(hour: 10, minute: 0),
        isEnabled: false,
      ),
    ];
  }
}
