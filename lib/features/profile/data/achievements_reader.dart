import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/database/record_repositories.dart';
import '../../../core/providers/health_goals_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'profile_achievements.dart';

/// Reúne lo que los registros dicen sobre los logros del usuario. Observa los
/// cuatro repositorios y las metas (todos provistos en `main.dart`), reduce todo
/// a números y deja el cálculo a [ProfileAchievements], que es puro y testeable.
/// Si algún repositorio aún no cargó, su conteo es 0: nunca se enseña más de lo
/// que hay.
///
/// Vive aparte de cualquier pantalla porque lo consumen dos: la tarjeta de
/// «Progreso de Autocuidado» del Perfil y la tarjeta lúdica del paciente en el
/// inicio. Antes era un método privado del Perfil; extraerlo evita duplicar la
/// misma lectura (y su definición de «meta cumplida») en dos sitios.
ProfileAchievements readAchievements(BuildContext context) {
  final anthro = context.watch<AnthropometricRepository>();
  final vitals = context.watch<VitalSignsRepository>();
  final lipid = context.watch<LipidRepository>();
  final body = context.watch<BodyCompositionRepository>();
  final goals = context.watch<HealthGoalsProvider>();

  // Meta corporal cumplida: mismo criterio que las tarjetas del panel
  // (`AnthropometricHistoryCard` y `BodyCompositionCard`), para no tener dos
  // definiciones que puedan discrepar. Basta con que se cumpla una.
  var bodyGoalMet = false;
  if (goals.medicalGoalsEnabled) {
    final weight = anthro.items.isNotEmpty ? anthro.items.first.weight : null;
    if (goals.targetWeight != null && weight != null) {
      bodyGoalMet = (weight - goals.targetWeight!).abs() <= 0.5;
    }
    final fat = body.items.isNotEmpty ? body.items.first.bodyFatPercent : null;
    if (!bodyGoalMet && goals.targetBodyFat != null && fat != null) {
      bodyGoalMet = fat <= goals.targetBodyFat!;
    }
  }

  // Ventana de historia: del registro más antiguo al más nuevo, sea de la
  // familia que sea. Cada lista viene ordenada por fecha descendente, así que
  // basta mirar sus extremos (primero = más nuevo, último = más antiguo). Se
  // recogen sólo los extremos y no todas las fechas: esto corre en cada
  // reconstrucción de la pantalla.
  final endpoints = <DateTime>[
    if (anthro.items.isNotEmpty) anthro.items.first.date,
    if (anthro.items.isNotEmpty) anthro.items.last.date,
    if (vitals.items.isNotEmpty) vitals.items.first.date,
    if (vitals.items.isNotEmpty) vitals.items.last.date,
    if (lipid.items.isNotEmpty) lipid.items.first.date,
    if (lipid.items.isNotEmpty) lipid.items.last.date,
    if (body.items.isNotEmpty) body.items.first.date,
    if (body.items.isNotEmpty) body.items.last.date,
  ];
  final spanDays = endpoints.isEmpty
      ? 0
      : endpoints
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .difference(endpoints.reduce((a, b) => a.isBefore(b) ? a : b))
            .inDays;

  return ProfileAchievements.from(
    AchievementInput(
      anthroCount: anthro.isLoaded ? anthro.items.length : 0,
      vitalsCount: vitals.isLoaded ? vitals.items.length : 0,
      lipidCount: lipid.isLoaded ? lipid.items.length : 0,
      bodyCount: body.isLoaded ? body.items.length : 0,
      longestVitalsDayStreak: longestConsecutiveDayStreak(
        vitals.items.map((r) => r.date),
      ),
      historySpanDays: spanDays,
      bodyGoalMet: bodyGoalMet,
    ),
  );
}

/// Nombre del rango para el tramo calculado. El tramo 1 reutiliza el rango que
/// ya existía; los otros dos se añadieron con la tarjeta de logros.
String rankName(AppLocalizations l10n, int tier) => switch (tier) {
  3 => l10n.profileRankTier3,
  2 => l10n.profileRankTier2,
  _ => l10n.profileRankObserver,
};
