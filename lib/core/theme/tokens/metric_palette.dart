import 'package:flutter/material.dart';

import 'tone.dart';

/// Las cuatro familias de indicador que la app registra. Cada una tiene una
/// identidad de color que el usuario aprende a reconocer de un vistazo: sabe
/// que la tarjeta roja es la del corazón antes de leer el título.
///
/// CONTRATO — igual que [ClinicalStatus], la identidad sobrevive al tema:
/// cada tema debe conservar la FAMILIA DE MATIZ de cada indicador (rojo para
/// signos vitales, ámbar para antropometría, verde-azulado para lípidos,
/// índigo para composición) y mantener las cuatro mutuamente distinguibles.
/// Lo verifica `test/core/theme/semantic_contract_test.dart`.
///
/// Lo que sí cambia por tema es el registro: «Pulso Clínico» las usa saturadas
/// y enérgicas; «Consulta Serena» las apaga hacia tierra. Mismo significado,
/// distinto volumen.
enum MetricFamily { vitals, anthropometry, lipids, bodyComposition }

/// Rendición visual de las familias de indicador para un tema concreto.
@immutable
class MetricPalette extends ThemeExtension<MetricPalette> {
  const MetricPalette({
    required this.vitals,
    required this.anthropometry,
    required this.lipids,
    required this.bodyComposition,
  });

  final Tone vitals;
  final Tone anthropometry;
  final Tone lipids;
  final Tone bodyComposition;

  Tone tone(MetricFamily family) => switch (family) {
    MetricFamily.vitals => vitals,
    MetricFamily.anthropometry => anthropometry,
    MetricFamily.lipids => lipids,
    MetricFamily.bodyComposition => bodyComposition,
  };

  @override
  MetricPalette copyWith({
    Tone? vitals,
    Tone? anthropometry,
    Tone? lipids,
    Tone? bodyComposition,
  }) {
    return MetricPalette(
      vitals: vitals ?? this.vitals,
      anthropometry: anthropometry ?? this.anthropometry,
      lipids: lipids ?? this.lipids,
      bodyComposition: bodyComposition ?? this.bodyComposition,
    );
  }

  @override
  MetricPalette lerp(MetricPalette? other, double t) {
    if (other == null) return this;
    return MetricPalette(
      vitals: Tone.lerp(vitals, other.vitals, t),
      anthropometry: Tone.lerp(anthropometry, other.anthropometry, t),
      lipids: Tone.lerp(lipids, other.lipids, t),
      bodyComposition: Tone.lerp(bodyComposition, other.bodyComposition, t),
    );
  }
}
