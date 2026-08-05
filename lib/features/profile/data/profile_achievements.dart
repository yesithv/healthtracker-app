/// Los logros del Perfil, calculados a partir de los registros reales.
///
/// La tarjeta «Progreso de Autocuidado» nació con el nivel, la barra y las seis
/// medallas escritas a mano: enseñaba «Nivel 1» y casi todo bloqueado aunque
/// hubiera dos años de historia detrás. Aquí vive el cálculo de verdad, y vive
/// APARTE de la pantalla —Dart puro, sin `BuildContext` ni Flutter— por la misma
/// razón que `demo_dataset.dart`: lo que no toca el árbol de widgets se puede
/// comprobar entero desde una prueba unitaria.
///
/// La entrada ([AchievementInput]) ya viene reducida a números; quien la arma es
/// la pantalla, leyendo los repositorios. Así este archivo no sabe de dónde
/// salen los datos, solo qué significan.
library;

/// Las seis medallas de la tarjeta. El orden es el de la rejilla.
enum ProfileBadge {
  firstStep,
  strongHeart,
  vitalHabit,
  awareness,
  balance,
  guardian,
}

/// Lo que la pantalla mide de los registros para alimentar el cálculo.
class AchievementInput {
  final int anthroCount;
  final int vitalsCount;
  final int lipidCount;
  final int bodyCount;

  /// Racha máxima de días de calendario CONSECUTIVOS con al menos un registro de
  /// signos vitales (ver [longestConsecutiveDayStreak]).
  final int longestVitalsDayStreak;

  /// Días entre el registro más antiguo y el más nuevo, sea de la familia que
  /// sea. Mide cuánto tiempo lleva la persona usando la app.
  final int historySpanDays;

  /// ¿Hay una meta corporal (peso o grasa) fijada y cumplida? Lo decide la
  /// pantalla con el mismo criterio que las tarjetas del panel, para no tener
  /// dos definiciones de «meta cumplida» que puedan discrepar.
  final bool bodyGoalMet;

  const AchievementInput({
    this.anthroCount = 0,
    this.vitalsCount = 0,
    this.lipidCount = 0,
    this.bodyCount = 0,
    this.longestVitalsDayStreak = 0,
    this.historySpanDays = 0,
    this.bodyGoalMet = false,
  });

  int get totalRecords => anthroCount + vitalsCount + lipidCount + bodyCount;

  bool get hasAllFamilies =>
      anthroCount > 0 && vitalsCount > 0 && lipidCount > 0 && bodyCount > 0;
}

/// El estado de gamificación que pinta la tarjeta: nivel, avance hacia el
/// siguiente y qué medallas están ganadas.
class ProfileAchievements {
  /// Nivel actual (mínimo 1).
  final int level;

  /// Registros acumulados dentro del nivel y los que pide el siguiente. Se
  /// exponen para el texto «{current} / {total} XP» que ya existe traducido; los
  /// registros hacen de XP. En el nivel máximo, `recordsForNextLevel == 0`.
  final int recordsIntoLevel;
  final int recordsForNextLevel;

  /// Tramo de rango (1..3) derivado del nivel; la pantalla lo traduce a un
  /// nombre. No es un cuarto dato independiente, es una lectura del nivel.
  final int rankTier;

  /// Medallas ganadas. Lo que no está aquí, está bloqueado.
  final Set<ProfileBadge> unlocked;

  const ProfileAchievements._({
    required this.level,
    required this.recordsIntoLevel,
    required this.recordsForNextLevel,
    required this.rankTier,
    required this.unlocked,
  });

  /// Avance hacia el siguiente nivel, 0..1, para la barra. En el nivel máximo la
  /// barra queda llena.
  double get progressToNext =>
      recordsForNextLevel == 0 ? 1.0 : recordsIntoLevel / recordsForNextLevel;

  bool isUnlocked(ProfileBadge badge) => unlocked.contains(badge);

  /// Hitos de registros acumulados que separan un nivel del siguiente. La curva
  /// es cada vez más exigente a propósito: los primeros niveles llegan rápido
  /// (para que alguien que empieza vea que sube) y los últimos piden constancia.
  /// Con ~630 registros la demo cae en el nivel 8.
  static const List<int> _milestones = [
    0,
    10,
    30,
    60,
    120,
    250,
    400,
    600,
    850,
    1150,
  ];

  /// Tramos de rango por nivel: 1–3 principiante, 4–6 constante, 7+ veterano.
  static int _tierForLevel(int level) {
    if (level >= 7) return 3;
    if (level >= 4) return 2;
    return 1;
  }

  factory ProfileAchievements.from(AchievementInput input) {
    final total = input.totalRecords;

    // Nivel = último hito alcanzado (el índice 0 es Nivel 1). Se recorre de
    // menor a mayor y se corta en el primero que aún no se ha alcanzado.
    var level = 1;
    for (var i = 1; i < _milestones.length; i++) {
      if (total >= _milestones[i]) {
        level = i + 1;
      } else {
        break;
      }
    }

    final bool atMax = level >= _milestones.length;
    final int floor = _milestones[level - 1];
    final int ceil = atMax ? floor : _milestones[level];

    return ProfileAchievements._(
      level: level,
      recordsIntoLevel: total - floor,
      recordsForNextLevel: atMax ? 0 : ceil - floor,
      rankTier: _tierForLevel(level),
      unlocked: {
        // Primer Paso — «Inicio del camino»: cualquier primer registro.
        if (total >= 1) ProfileBadge.firstStep,
        // Corazón Fuerte — «Salud Cardio»: seguimiento sostenido de la tensión.
        if (input.vitalsCount >= 20) ProfileBadge.strongHeart,
        // Hábito Vital — «7 días seguidos»: una racha diaria real.
        if (input.longestVitalsDayStreak >= 7) ProfileBadge.vitalHabit,
        // Conciencia — «Big Picture»: las cuatro familias registradas.
        if (input.hasAllFamilies) ProfileBadge.awareness,
        // Equilibrio — «Meta corporal»: una meta de cuerpo cumplida.
        if (input.bodyGoalMet) ProfileBadge.balance,
        // Guardián — «Compromiso»: constancia en el tiempo o en volumen.
        if (input.historySpanDays >= 180 || total >= 100) ProfileBadge.guardian,
      },
    );
  }
}

/// Racha máxima de días de calendario CONSECUTIVOS presentes en [dates].
///
/// Cuenta días, no registros: dos tomas el mismo día son un día. Ordena los días
/// distintos y busca el tramo más largo sin huecos. Vacío → 0.
int longestConsecutiveDayStreak(Iterable<DateTime> dates) {
  final days =
      dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
        ..sort();
  if (days.isEmpty) return 0;

  var longest = 1;
  var current = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
