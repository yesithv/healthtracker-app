import 'package:flutter/material.dart';

import 'tone.dart';

/// Severidad clínica canónica: el ÚNICO vocabulario con el que la interfaz
/// habla de «qué tan bien está este valor».
///
/// CONTRATO — esto es lo que hace que los colores sigan siendo semánticos por
/// mucho que el usuario cambie de tema:
///
/// 1. El mapeo indicador → [ClinicalStatus] es criterio CLÍNICO y vive en
///    `core/utils/health_classifiers.dart`. No depende del tema. Ningún tema
///    puede reinterpretar si 128/84 está «elevada»: eso lo dicen los rangos
///    del backoffice, no la paleta.
/// 2. El tema aporta SOLO el acabado (matiz exacto, saturación, superficie).
/// 3. Cada tema debe respetar la FAMILIA DE MATIZ de cada estado —frío para
///    [info], verde para [optimal], ámbar para [caution], rojo para [alert]—
///    y un contraste mínimo AA. Esto no es una convención de buena voluntad:
///    lo verifica `test/core/theme/semantic_contract_test.dart` para todos los
///    temas del catálogo, y el build falla si un tema lo rompe.
///
/// El resultado es que un usuario que aprendió «ámbar = ojo con esto» en un
/// tema no tiene que reaprender nada al cambiar al otro.
enum ClinicalStatus {
  /// Por debajo del rango. Anómalo, pero no es el extremo de riesgo.
  /// Familia de matiz: FRÍA (azul / pizarra).
  info,

  /// En rango, deseable. Familia de matiz: VERDE.
  optimal,

  /// Límite alto o borderline. Merece atención, no alarma.
  /// Familia de matiz: ÁMBAR / OCRE.
  caution,

  /// Fuera de rango por el extremo de riesgo. Familia de matiz: ROJA.
  alert,

  /// Sin valoración clínica (vacío, no aplica, informativo).
  /// Familia de matiz: NEUTRA. Exento de la regla de matiz.
  neutral,
}

/// Los cuatro estados con carga clínica real. [ClinicalStatus.neutral] queda
/// fuera porque no afirma nada sobre la salud del usuario.
const List<ClinicalStatus> kDiagnosticStatuses = [
  ClinicalStatus.info,
  ClinicalStatus.optimal,
  ClinicalStatus.caution,
  ClinicalStatus.alert,
];

/// Rendición visual de los estados clínicos para un tema concreto.
///
/// Se lee con `Theme.of(context).clinical` (ver `theme_context.dart`), que es
/// una búsqueda O(1) en el `InheritedWidget` del tema: sin coste medible por
/// widget y sin necesidad de que nadie escuche a un provider.
@immutable
class ClinicalPalette extends ThemeExtension<ClinicalPalette> {
  const ClinicalPalette({
    required this.info,
    required this.optimal,
    required this.caution,
    required this.alert,
    required this.neutral,
    required this.badgeIdiom,
  });

  final Tone info;
  final Tone optimal;
  final Tone caution;
  final Tone alert;
  final Tone neutral;

  /// Cómo se dibujan las insignias de estado en este tema.
  final BadgeIdiom badgeIdiom;

  /// Tono correspondiente a [status]. Exhaustivo por construcción: añadir un
  /// estado nuevo rompe la compilación aquí y en cada tema, que es exactamente
  /// lo que queremos.
  Tone tone(ClinicalStatus status) => switch (status) {
    ClinicalStatus.info => info,
    ClinicalStatus.optimal => optimal,
    ClinicalStatus.caution => caution,
    ClinicalStatus.alert => alert,
    ClinicalStatus.neutral => neutral,
  };

  /// Rampa de severidad de menor a mayor riesgo, para barras y degradados
  /// (p. ej. la escala de IMC del panel). Mantiene el orden clínico, no el
  /// orden estético.
  List<Color> get severityRamp => [
    info.accent,
    optimal.accent,
    caution.accent,
    alert.accent,
  ];

  @override
  ClinicalPalette copyWith({
    Tone? info,
    Tone? optimal,
    Tone? caution,
    Tone? alert,
    Tone? neutral,
    BadgeIdiom? badgeIdiom,
  }) {
    return ClinicalPalette(
      info: info ?? this.info,
      optimal: optimal ?? this.optimal,
      caution: caution ?? this.caution,
      alert: alert ?? this.alert,
      neutral: neutral ?? this.neutral,
      badgeIdiom: badgeIdiom ?? this.badgeIdiom,
    );
  }

  @override
  ClinicalPalette lerp(ClinicalPalette? other, double t) {
    if (other == null) return this;
    return ClinicalPalette(
      info: Tone.lerp(info, other.info, t),
      optimal: Tone.lerp(optimal, other.optimal, t),
      caution: Tone.lerp(caution, other.caution, t),
      alert: Tone.lerp(alert, other.alert, t),
      neutral: Tone.lerp(neutral, other.neutral, t),
      // Los idiomas son discretos: no se interpolan, conmutan a mitad de
      // camino para no dejar un estado intermedio sin sentido.
      badgeIdiom: t < 0.5 ? badgeIdiom : other.badgeIdiom,
    );
  }
}
