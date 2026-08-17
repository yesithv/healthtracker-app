import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// Clave que recuerda de QUIÉN son los datos que residen hoy en el dispositivo
/// (el `publicId` del paciente), o ausente = ninguno. Persiste entre sesiones: es
/// lo que permite detectar, al iniciar sesión, que entra un paciente distinto y
/// que hay que limpiar antes de sincronizar.
const String _kDataOwner = 'data_owner_public_id';

/// Paciente dueño de los datos locales actuales (null = dispositivo vacío).
Future<String?> currentDataOwner() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kDataOwner);
}

/// Marca al paciente [publicId] como dueño de los datos locales actuales.
Future<void> setDataOwner(String publicId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kDataOwner, publicId);
}

/// Borra TODOS los datos personales/de salud del dispositivo para que no se filtren
/// entre usuarios: las 4 tablas de registros, las 3 de medicamentos, el perfil, el
/// estado del onboarding, las metas y los recordatorios. NO toca preferencias de
/// app/dispositivo (idioma, unidades, catálogos, rangos de referencia, caché de Descubrir).
///
/// Lee los providers del [context] antes de los await para no usar el BuildContext tras
/// un gap asíncrono.
Future<void> wipeLocalUserData(BuildContext context) async {
  final profile = context.read<UserProfileProvider>();
  final onboarding = context.read<OnboardingProvider>();
  final goals = context.read<HealthGoalsProvider>();
  final reminders = context.read<RemindersProvider>();

  await AnthropometricRepository.instance.clearAll();
  await VitalSignsRepository.instance.clearAll();
  await LipidRepository.instance.clearAll();
  await BodyCompositionRepository.instance.clearAll();

  await MedicationRepository.instance.clearAll();
  await MedicationDoseRepository.instance.clearAll();
  await MedicationLogRepository.instance.clearAll();

  await profile.clear();
  await onboarding.reset();
  await goals.clear();
  await reminders.clear();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kDataOwner);
}
