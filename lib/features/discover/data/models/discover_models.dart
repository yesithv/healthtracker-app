// Content models for the Discover feed that mirror the backoffice
// "Rutinas" and "Retos" content types 1:1, so the same authored data can flow
// from the backoffice export into the mobile app.

/// Difficulty level of a workout routine. Values match the Spanish labels used
/// in the backoffice (`Principiante` / `Intermedio` / `Avanzado`).
enum ContentLevel {
  principiante,
  intermedio,
  avanzado;

  static ContentLevel fromJson(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'intermedio':
        return ContentLevel.intermedio;
      case 'avanzado':
        return ContentLevel.avanzado;
      default:
        return ContentLevel.principiante;
    }
  }
}

/// Lifecycle of a challenge, matching the backoffice `ChallengeStatus`.
enum ChallengeStatus {
  programado,
  activo,
  finalizado;

  static ChallengeStatus fromJson(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'activo':
        return ChallengeStatus.activo;
      case 'finalizado':
        return ChallengeStatus.finalizado;
      default:
        return ChallengeStatus.programado;
    }
  }
}

/// A guided workout routine (backoffice "Rutinas").
class Routine {
  final String id;
  final String title;
  final String subtitle;

  /// Taxonomy key (`sports`, `heart`, ...) used for the accent colour/icon.
  final String category;
  final ContentLevel level;
  final int durationMin;
  final int exercises;

  const Routine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.level,
    required this.durationMin,
    this.exercises = 0,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? 'sports',
      level: ContentLevel.fromJson(json['level'] as String?),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
      exercises: (json['exercises'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A community challenge (backoffice "Retos").
class Challenge {
  final String id;
  final String title;
  final String goal;
  final int participants;
  final ChallengeStatus status;
  final int durationDays;

  const Challenge({
    required this.id,
    required this.title,
    required this.goal,
    required this.participants,
    required this.status,
    this.durationDays = 0,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      participants: (json['participants'] as num?)?.toInt() ?? 0,
      status: ChallengeStatus.fromJson(json['status'] as String?),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A short daily health tip surfaced in the Discover hero.
class DailyTip {
  final String id;
  final String text;

  const DailyTip({required this.id, required this.text});

  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      id: json['id'] as String,
      // Accept either `text` (new) or `subtitle` (legacy daily article shape).
      text: (json['text'] ?? json['subtitle'] ?? '') as String,
    );
  }
}
