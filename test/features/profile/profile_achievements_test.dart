import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/profile/data/profile_achievements.dart';

/// La tarjeta «Progreso de Autocuidado» dejó de estar escrita a mano y ahora
/// sale de los registros. El riesgo de un calculador así es que mienta hacia
/// arriba —enseñar medallas que no se han ganado— o hacia abajo —dejar a alguien
/// con dos años de historia en Nivel 1—. Estas pruebas fijan las dos fronteras.
void main() {
  group('nivel y progreso ·', () {
    test('sin registros: Nivel 1, barra a cero', () {
      final a = ProfileAchievements.from(const AchievementInput());
      expect(a.level, 1);
      expect(a.progressToNext, 0.0);
      // Nada ganado todavía, ni siquiera el primer paso.
      expect(a.unlocked, isEmpty);
    });

    test('el primer registro enciende «Primer Paso» y nada más', () {
      final a = ProfileAchievements.from(
        const AchievementInput(vitalsCount: 1),
      );
      expect(a.unlocked, {ProfileBadge.firstStep});
    });

    test('el nivel sube por hitos y la barra mide el tramo', () {
      // 45 registros: pasado el hito de 30 (Nivel 3), a mitad de camino del de
      // 60. La barra debe leer 15/30 = 0.5.
      final a = ProfileAchievements.from(
        const AchievementInput(vitalsCount: 45),
      );
      expect(a.level, 3);
      expect(a.progressToNext, closeTo(0.5, 0.001));
      expect(a.recordsIntoLevel, 15);
      expect(a.recordsForNextLevel, 30);
    });

    test('en el nivel máximo la barra queda llena, no se desborda', () {
      final a = ProfileAchievements.from(
        const AchievementInput(vitalsCount: 5000),
      );
      expect(a.recordsForNextLevel, 0);
      expect(a.progressToNext, 1.0);
    });
  });

  group('el visitante de la demo ·', () {
    // Lo que ve quien entra a la demo: ~630 registros repartidos, dos años de
    // historia, meta corporal cumplida y —clave— signos vitales cada dos días,
    // así que su racha diaria máxima es 1.
    final demo = ProfileAchievements.from(
      const AchievementInput(
        anthroCount: 105,
        vitalsCount: 420,
        lipidCount: 9,
        bodyCount: 105,
        longestVitalsDayStreak: 1,
        historySpanDays: 730,
        bodyGoalMet: true,
      ),
    );

    test('llega a un nivel alto', () {
      // 639 registros → pasado el hito de 600 (Nivel 8).
      expect(demo.level, 8);
    });

    test('gana cinco de las seis medallas', () {
      expect(demo.unlocked, hasLength(5));
      expect(demo.unlocked, contains(ProfileBadge.firstStep));
      expect(demo.unlocked, contains(ProfileBadge.strongHeart));
      expect(demo.unlocked, contains(ProfileBadge.awareness));
      expect(demo.unlocked, contains(ProfileBadge.balance));
      expect(demo.unlocked, contains(ProfileBadge.guardian));
    });

    test('«7 días seguidos» queda bloqueada: registra cada dos días', () {
      // No es un fallo, es lo honesto: el paciente ficticio no mide a diario, así
      // que esa medalla NO puede estar ganada. Si algún día se encendiera con
      // racha 1, el calculador estaría mintiendo.
      expect(demo.isUnlocked(ProfileBadge.vitalHabit), isFalse);
    });

    test('el rango es el del tramo alto', () {
      expect(demo.rankTier, 3);
    });
  });

  group('reglas de cada medalla ·', () {
    test('«Conciencia» exige las cuatro familias', () {
      final tres = ProfileAchievements.from(
        const AchievementInput(anthroCount: 5, vitalsCount: 5, lipidCount: 5),
      );
      expect(tres.isUnlocked(ProfileBadge.awareness), isFalse);

      final cuatro = ProfileAchievements.from(
        const AchievementInput(
          anthroCount: 5,
          vitalsCount: 5,
          lipidCount: 5,
          bodyCount: 1,
        ),
      );
      expect(cuatro.isUnlocked(ProfileBadge.awareness), isTrue);
    });

    test('«Equilibrio» sigue a la meta corporal', () {
      const base = AchievementInput(vitalsCount: 5);
      expect(
        ProfileAchievements.from(base).isUnlocked(ProfileBadge.balance),
        isFalse,
      );

      const conMeta = AchievementInput(vitalsCount: 5, bodyGoalMet: true);
      expect(
        ProfileAchievements.from(conMeta).isUnlocked(ProfileBadge.balance),
        isTrue,
      );
    });

    test('«Guardián» se gana por tiempo O por volumen', () {
      // Poca historia y pocos registros: aún no.
      expect(
        ProfileAchievements.from(
          const AchievementInput(vitalsCount: 10, historySpanDays: 30),
        ).isUnlocked(ProfileBadge.guardian),
        isFalse,
      );
      // Medio año de historia basta, aunque haya pocos registros.
      expect(
        ProfileAchievements.from(
          const AchievementInput(vitalsCount: 10, historySpanDays: 200),
        ).isUnlocked(ProfileBadge.guardian),
        isTrue,
      );
      // O muchos registros, aunque sean recientes.
      expect(
        ProfileAchievements.from(
          const AchievementInput(vitalsCount: 120, historySpanDays: 20),
        ).isUnlocked(ProfileBadge.guardian),
        isTrue,
      );
    });
  });

  group('racha de días consecutivos ·', () {
    DateTime d(int day) => DateTime(2026, 1, day);

    test('días seguidos cuentan; los huecos reinician', () {
      // 1,2,3 seguidos (racha 3), hueco, 10,11 (racha 2). Máxima = 3.
      final streak = longestConsecutiveDayStreak([
        d(1),
        d(2),
        d(3),
        d(10),
        d(11),
      ]);
      expect(streak, 3);
    });

    test('dos tomas el mismo día son un día, no dos', () {
      final streak = longestConsecutiveDayStreak([
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 20),
        DateTime(2026, 1, 2, 9),
      ]);
      expect(streak, 2);
    });

    test('vacío es cero; un solo día es uno', () {
      expect(longestConsecutiveDayStreak(const []), 0);
      expect(longestConsecutiveDayStreak([d(5)]), 1);
    });

    test('el orden de entrada no importa', () {
      expect(longestConsecutiveDayStreak([d(3), d(1), d(2)]), 3);
    });
  });
}
