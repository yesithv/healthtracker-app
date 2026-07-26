import 'package:flutter/material.dart';

/// Un *tono* es la unidad mínima del sistema de color semántico: la terna que
/// hace falta para pintar un significado (un estado clínico, una familia de
/// indicador) en cualquiera de los dos idiomas visuales que usa la app.
///
/// * [accent]   — el color con la carga semántica. Trazos, iconos, cifras y
///               bordes se pintan con él SOBRE la superficie de la tarjeta.
/// * [surface]  — relleno suave del mismo matiz, para chips «soft».
/// * [onAccent] — texto/icono legible ENCIMA de [accent], para chips «solid».
///
/// Un tono es inmutable y interpolable: eso permite que el cambio de tema se
/// anime en un solo frame vía [ThemeExtension.lerp] sin recrear widgets.
@immutable
class Tone {
  const Tone({
    required this.accent,
    required this.surface,
    required this.onAccent,
  });

  final Color accent;
  final Color surface;
  final Color onAccent;

  /// Deriva un tono a partir de [accent] mezclándolo con [canvas]. Útil para
  /// no escribir a mano superficies que son simple tinte del acento.
  factory Tone.from(
    Color accent, {
    required Color canvas,
    double surfaceBlend = 0.12,
    Color onAccent = const Color(0xFFFFFFFF),
  }) {
    return Tone(
      accent: accent,
      surface: Color.lerp(canvas, accent, surfaceBlend)!,
      onAccent: onAccent,
    );
  }

  Tone copyWith({Color? accent, Color? surface, Color? onAccent}) => Tone(
    accent: accent ?? this.accent,
    surface: surface ?? this.surface,
    onAccent: onAccent ?? this.onAccent,
  );

  static Tone lerp(Tone a, Tone b, double t) => Tone(
    accent: Color.lerp(a.accent, b.accent, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is Tone &&
      other.accent == accent &&
      other.surface == surface &&
      other.onAccent == onAccent;

  @override
  int get hashCode => Object.hash(accent, surface, onAccent);
}

/// Cómo dibuja un tema sus insignias de estado. No es decoración arbitraria:
/// es el idioma visual del tema, y cambiarlo por tema es justamente lo que
/// permite que «Pulso Clínico» se sienta enérgico y «Consulta Serena» calmado
/// sin que ningún widget tenga que preguntar qué tema está activo.
enum BadgeIdiom {
  /// Relleno sólido con [Tone.accent] y texto [Tone.onAccent]. Alto contraste.
  solid,

  /// Relleno suave con [Tone.surface] y texto [Tone.accent]. Bajo ruido visual.
  soft,
}
