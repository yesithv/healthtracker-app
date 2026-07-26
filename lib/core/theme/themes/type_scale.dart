import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Constructores de estilo por familia tipográfica.
///
/// Newsreader e Inter se empaquetan como fuentes VARIABLES (un único .ttf con
/// eje `wght`). En Flutter eso obliga a pedir el peso por [ui.FontVariation]:
/// `fontWeight` a solas describe el estilo pero no mueve el eje, así que sin la
/// variación el texto se rendería siempre en el peso por defecto. Aquí se piden
/// LOS DOS —la variación mueve el eje, el `fontWeight` mantiene correctas las
/// métricas y el fallback— y así ninguna pantalla tiene que saberlo.
///
/// IBM Plex se empaqueta con instancias estáticas (400 y 600), que Flutter
/// resuelve por `fontWeight` sin más.
class TypeScale {
  const TypeScale._();

  /// Escala del sistema de diseño: 11 · 12 · 13 · 15 · 17 · 21 · 27 · 34 · 54.
  /// No se usan tamaños fuera de esta lista.
  static const double xs = 11;
  static const double sm = 12;
  static const double md = 13;
  static const double base = 15;
  static const double lg = 17;
  static const double xl = 21;
  static const double xxl = 27;
  static const double display = 34;

  static FontWeight weightOf(double w) => switch (w) {
    <= 250 => FontWeight.w200,
    <= 350 => FontWeight.w300,
    <= 450 => FontWeight.w400,
    <= 550 => FontWeight.w500,
    <= 650 => FontWeight.w600,
    <= 750 => FontWeight.w700,
    _ => FontWeight.w800,
  };

  /// Estilo en una fuente VARIABLE (Newsreader, Inter).
  static TextStyle variable(
    String family, {
    required double size,
    required double weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weightOf(weight),
      fontVariations: [ui.FontVariation('wght', weight)],
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Estilo en una fuente con instancias ESTÁTICAS (IBM Plex Sans/Mono).
  static TextStyle static_(
    String family, {
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
