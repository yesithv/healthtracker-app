import 'package:flutter/material.dart';

import 'tone.dart';

/// Las categorías editoriales de «Descubre». Las claves las fija la taxonomía
/// del backoffice, así que llegan como texto y se traducen aquí.
enum ContentCategory { heart, nutrition, emotional, sports, sleep, daily }

/// El nivel de una rutina. Es una rampa de INTENSIDAD, no un estado clínico:
/// una rutina avanzada no está «mal», solo pide más.
enum ContentLevelStep { easy, medium, hard }

/// Cómo va un reto en el tiempo.
enum ContentStatus { active, scheduled, closed }

/// CUARTO VOCABULARIO de color, junto a [ClinicalStatus], [MetricFamily] y las
/// superficies: la identidad del CONTENIDO editorial.
///
/// Existe porque «Descubre» no habla de indicadores ni de estados de salud —un
/// artículo de nutrición no está «óptimo»— y sin un vocabulario propio la
/// sección tenía que inventarse los colores. Los tenía en
/// `features/discover/presentation/theme/discover_palette.dart`: seis acentos
/// escritos a mano que ningún tema podía tocar, así que era la única parte de la
/// app que se veía igual pasara lo que pasara.
///
/// CONTRATO — como las familias de indicador, la identidad sobrevive al tema:
/// cada tema conserva la familia de matiz de cada categoría (rojo para corazón,
/// verde para nutrición, violeta para emocional, naranja para deporte, índigo
/// para sueño, turquesa para el día a día) y las mantiene mutuamente
/// distinguibles. Lo que cambia es el registro: vivo en «Pulso Clínico»,
/// apagado hacia tierra en «Consulta Serena».
@immutable
class ContentPalette extends ThemeExtension<ContentPalette> {
  const ContentPalette({
    required this.heart,
    required this.nutrition,
    required this.emotional,
    required this.sports,
    required this.sleep,
    required this.daily,
    required this.levelEasy,
    required this.levelMedium,
    required this.levelHard,
    required this.statusActive,
    required this.statusScheduled,
    required this.statusClosed,
  });

  final Tone heart;
  final Tone nutrition;
  final Tone emotional;
  final Tone sports;
  final Tone sleep;
  final Tone daily;

  final Tone levelEasy;
  final Tone levelMedium;
  final Tone levelHard;

  final Tone statusActive;
  final Tone statusScheduled;
  final Tone statusClosed;

  Tone tone(ContentCategory c) => switch (c) {
    ContentCategory.heart => heart,
    ContentCategory.nutrition => nutrition,
    ContentCategory.emotional => emotional,
    ContentCategory.sports => sports,
    ContentCategory.sleep => sleep,
    ContentCategory.daily => daily,
  };

  Tone level(ContentLevelStep l) => switch (l) {
    ContentLevelStep.easy => levelEasy,
    ContentLevelStep.medium => levelMedium,
    ContentLevelStep.hard => levelHard,
  };

  Tone status(ContentStatus s) => switch (s) {
    ContentStatus.active => statusActive,
    ContentStatus.scheduled => statusScheduled,
    ContentStatus.closed => statusClosed,
  };

  /// Todas las categorías, para que el contrato semántico las recorra sin tener
  /// que enumerarlas otra vez.
  List<Tone> get categories => [
    heart,
    nutrition,
    emotional,
    sports,
    sleep,
    daily,
  ];

  /// Traduce una clave de la taxonomía del backoffice. Devuelve null si no la
  /// reconoce, para que el llamador use su color por defecto en vez de fallar:
  /// el backoffice puede publicar una categoría nueva antes de que la app sepa
  /// pintarla, y eso no debe dejar la pantalla en blanco.
  static ContentCategory? tryParse(String key) => switch (key) {
    'heart' => ContentCategory.heart,
    'nutrition' => ContentCategory.nutrition,
    'emotional' => ContentCategory.emotional,
    'sports' => ContentCategory.sports,
    'sleep' => ContentCategory.sleep,
    'daily' => ContentCategory.daily,
    _ => null,
  };

  @override
  ContentPalette copyWith({
    Tone? heart,
    Tone? nutrition,
    Tone? emotional,
    Tone? sports,
    Tone? sleep,
    Tone? daily,
    Tone? levelEasy,
    Tone? levelMedium,
    Tone? levelHard,
    Tone? statusActive,
    Tone? statusScheduled,
    Tone? statusClosed,
  }) {
    return ContentPalette(
      heart: heart ?? this.heart,
      nutrition: nutrition ?? this.nutrition,
      emotional: emotional ?? this.emotional,
      sports: sports ?? this.sports,
      sleep: sleep ?? this.sleep,
      daily: daily ?? this.daily,
      levelEasy: levelEasy ?? this.levelEasy,
      levelMedium: levelMedium ?? this.levelMedium,
      levelHard: levelHard ?? this.levelHard,
      statusActive: statusActive ?? this.statusActive,
      statusScheduled: statusScheduled ?? this.statusScheduled,
      statusClosed: statusClosed ?? this.statusClosed,
    );
  }

  @override
  ContentPalette lerp(ContentPalette? other, double t) {
    if (other == null) return this;
    return ContentPalette(
      heart: Tone.lerp(heart, other.heart, t),
      nutrition: Tone.lerp(nutrition, other.nutrition, t),
      emotional: Tone.lerp(emotional, other.emotional, t),
      sports: Tone.lerp(sports, other.sports, t),
      sleep: Tone.lerp(sleep, other.sleep, t),
      daily: Tone.lerp(daily, other.daily, t),
      levelEasy: Tone.lerp(levelEasy, other.levelEasy, t),
      levelMedium: Tone.lerp(levelMedium, other.levelMedium, t),
      levelHard: Tone.lerp(levelHard, other.levelHard, t),
      statusActive: Tone.lerp(statusActive, other.statusActive, t),
      statusScheduled: Tone.lerp(statusScheduled, other.statusScheduled, t),
      statusClosed: Tone.lerp(statusClosed, other.statusClosed, t),
    );
  }
}
