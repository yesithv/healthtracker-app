import 'package:flutter/material.dart';

/// Roles tipográficos de la app.
///
/// La interfaz nunca pide «Newsreader 34» ni «Inter bold 26»: pide el ROL
/// (`numeral`, `sectionLabel`, `meta`…) y el tema decide con qué familia, peso
/// y tamaño se sirve. Así «Consulta Serena» puede poner las cifras en serif y
/// las etiquetas en monoespaciada, y «Pulso Clínico» resolverlas ambas en Inter,
/// sin tocar una sola pantalla.
///
/// Los tamaños viven aquí y no en las pantallas, pero la MAQUETA no depende de
/// ellos: los textos fluyen en `Flexible`/`Wrap` y el diseño se validó con
/// cadenas un 40 % más largas (alemán), así que un tema con tipografía más
/// ancha no rompe la composición ni provoca reflow en cascada.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.displayMeta,
    required this.screenTitle,
    required this.cardTitle,
    required this.sectionLabel,
    required this.fieldLabel,
    required this.numeral,
    required this.numeralSmall,
    required this.numeralUnit,
    required this.body,
    required this.hint,
    required this.meta,
    required this.badge,
    required this.button,
  });

  /// Logotipo de texto: splash y cabecera de marca.
  final TextStyle display;

  /// Bajada del logotipo y textos de estado del arranque.
  final TextStyle displayMeta;

  /// Título de pantalla («Tus datos», «Unidades de medida»).
  final TextStyle screenTitle;

  /// Título de una tarjeta («Antropometría», «Signos vitales»). Texto normal en
  /// caja mixta: es un nombre, no un rótulo.
  final TextStyle cardTitle;

  /// Rótulo de sección en VERSALITAS («PALETA», «PESO», «PASO 1 DE 3»). Las
  /// mayúsculas las aplica quien lo usa; el estilo aporta familia y tracking.
  /// Separado de [cardTitle] a propósito: en «Consulta Serena» uno va en sans
  /// de caja mixta y el otro en monoespaciada versalita, y confundirlos ponía
  /// los títulos de las tarjetas en mono, que no es lo que pide el diseño.
  final TextStyle sectionLabel;

  /// Etiqueta de campo de formulario.
  final TextStyle fieldLabel;

  /// Cifra protagonista de una tarjeta (peso, IMC, tensión).
  final TextStyle numeral;

  /// Cifra secundaria, en tarjetas con varias lecturas.
  final TextStyle numeralSmall;

  /// Unidad que acompaña a una cifra (kg, mmHg, mg/dL).
  final TextStyle numeralUnit;

  /// Texto corrido: descripciones y ayudas.
  final TextStyle body;

  /// TEXTO DE EJEMPLO dentro de un campo vacío («email@ejemplo.com»,
  /// «300 123 4567»).
  ///
  /// Existe porque sin él no se distinguía de un dato ya escrito: el ejemplo
  /// salía en el gris por defecto de Material, del mismo tamaño y del mismo
  /// corte que lo que teclea el usuario, así que en el alta la gente daba por
  /// rellenos campos que estaban vacíos.
  ///
  /// Lleva DOS señales, no una. La cursiva marca la diferencia aunque el
  /// contraste falle —una pantalla al sol, una vista cansada, alguien que no
  /// distingue bien los grises—, y el gris apagado la marca aunque la
  /// tipografía del tema no traiga cursiva de verdad y el motor tenga que
  /// inclinarla él. Con una sola señal, cada tema nuevo vuelve a jugársela.
  final TextStyle hint;

  /// Metadatos: fechas, notas al pie, texto auxiliar.
  final TextStyle meta;

  /// Texto de una insignia de estado.
  final TextStyle badge;

  /// Etiqueta de botón.
  final TextStyle button;

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? displayMeta,
    TextStyle? screenTitle,
    TextStyle? cardTitle,
    TextStyle? sectionLabel,
    TextStyle? fieldLabel,
    TextStyle? numeral,
    TextStyle? numeralSmall,
    TextStyle? numeralUnit,
    TextStyle? body,
    TextStyle? hint,
    TextStyle? meta,
    TextStyle? badge,
    TextStyle? button,
  }) {
    return AppTypography(
      display: display ?? this.display,
      displayMeta: displayMeta ?? this.displayMeta,
      screenTitle: screenTitle ?? this.screenTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      numeral: numeral ?? this.numeral,
      numeralSmall: numeralSmall ?? this.numeralSmall,
      numeralUnit: numeralUnit ?? this.numeralUnit,
      body: body ?? this.body,
      hint: hint ?? this.hint,
      meta: meta ?? this.meta,
      badge: badge ?? this.badge,
      button: button ?? this.button,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    return AppTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      displayMeta: TextStyle.lerp(displayMeta, other.displayMeta, t)!,
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      fieldLabel: TextStyle.lerp(fieldLabel, other.fieldLabel, t)!,
      numeral: TextStyle.lerp(numeral, other.numeral, t)!,
      numeralSmall: TextStyle.lerp(numeralSmall, other.numeralSmall, t)!,
      numeralUnit: TextStyle.lerp(numeralUnit, other.numeralUnit, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      hint: TextStyle.lerp(hint, other.hint, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      badge: TextStyle.lerp(badge, other.badge, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}
