import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the user's optional medical/wellness targets. Extracted from the former
/// God-object PreferencesProvider so goal changes only rebuild the screens that
/// actually use them (dashboard cards, goals editor).
class HealthGoalsProvider extends ChangeNotifier {
  static const String _enabledKey = 'medical_goals_enabled';
  static const String _weightKey = 'target_weight';
  static const String _bodyFatKey = 'target_body_fat';
  static const String _muscleMassKey = 'target_muscle_mass';
  static const String _visceralFatKey = 'target_visceral_fat';

  bool _medicalGoalsEnabled = false;
  double? _targetWeight;
  double? _targetBodyFat;
  double? _targetMuscleMass;
  int? _targetVisceralFat;

  bool get medicalGoalsEnabled => _medicalGoalsEnabled;
  double? get targetWeight => _targetWeight;
  double? get targetBodyFat => _targetBodyFat;
  double? get targetMuscleMass => _targetMuscleMass;
  int? get targetVisceralFat => _targetVisceralFat;

  HealthGoalsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _medicalGoalsEnabled = prefs.getBool(_enabledKey) ?? false;
    _targetWeight = prefs.getDouble(_weightKey);
    _targetBodyFat = prefs.getDouble(_bodyFatKey);
    _targetMuscleMass = prefs.getDouble(_muscleMassKey);
    _targetVisceralFat = prefs.getInt(_visceralFatKey);
    notifyListeners();
  }

  Future<void> updateHealthGoals({
    required bool enabled,
    double? weight,
    double? bodyFat,
    double? muscleMass,
    int? visceralFat,
  }) async {
    _medicalGoalsEnabled = enabled;
    _targetWeight = weight;
    _targetBodyFat = bodyFat;
    _targetMuscleMass = muscleMass;
    _targetVisceralFat = visceralFat;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (weight != null) {
      await prefs.setDouble(_weightKey, weight);
    } else {
      await prefs.remove(_weightKey);
    }
    if (bodyFat != null) {
      await prefs.setDouble(_bodyFatKey, bodyFat);
    } else {
      await prefs.remove(_bodyFatKey);
    }
    if (muscleMass != null) {
      await prefs.setDouble(_muscleMassKey, muscleMass);
    } else {
      await prefs.remove(_muscleMassKey);
    }
    if (visceralFat != null) {
      await prefs.setInt(_visceralFatKey, visceralFat);
    } else {
      await prefs.remove(_visceralFatKey);
    }
  }

  /// Trae las metas del servidor SIN pisar las que la persona ya tenga en este
  /// teléfono: solo se aplican si aquí no hay ninguna.
  ///
  /// Es la mitad que hacía falta para que cambiar de móvil no cueste las metas.
  /// La regla —solo si no hay nada— es la que permite llamarla en cada arranque
  /// con sesión sin arriesgar una edición local que aún no se haya subido.
  Future<void> hydrate({
    required bool enabled,
    double? weight,
    double? bodyFat,
    double? muscleMass,
    int? visceralFat,
  }) async {
    final hasLocalGoals =
        _medicalGoalsEnabled ||
        _targetWeight != null ||
        _targetBodyFat != null ||
        _targetMuscleMass != null ||
        _targetVisceralFat != null;
    if (hasLocalGoals) return;

    await updateHealthGoals(
      enabled: enabled,
      weight: weight,
      bodyFat: bodyFat,
      muscleMass: muscleMass,
      visceralFat: visceralFat,
    );
  }

  /// Re-reads goals from storage (e.g. after a restored backup).
  Future<void> reload() => _load();

  /// Borra las metas del usuario (al cerrar sesión / cambiar de paciente).
  Future<void> clear() async {
    _medicalGoalsEnabled = false;
    _targetWeight = null;
    _targetBodyFat = null;
    _targetMuscleMass = null;
    _targetVisceralFat = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _enabledKey,
      _weightKey,
      _bodyFatKey,
      _muscleMassKey,
      _visceralFatKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
