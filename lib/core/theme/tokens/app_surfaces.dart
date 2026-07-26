import 'package:flutter/material.dart';

/// Superficies, tinta y forma: el «material» del que está hecho el tema.
///
/// Aquí vive todo lo que NO tiene carga semántica pero define el carácter
/// visual: el color del lienzo, si las tarjetas flotan con sombra o descansan
/// planas, cuánto se redondean los controles, qué gris usa el texto auxiliar.
///
/// Nada de esto afecta la disposición ni el tamaño de los elementos: la
/// navegación, los iconos y la maqueta son idénticos entre temas. Un tema
/// cambia el acabado, no la estructura — por eso cambiar de tema no reflowea
/// la pantalla, sólo la repinta.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.canvas,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.inset,
    required this.track,
    required this.divider,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.brand,
    required this.onBrand,
    required this.radiusCard,
    required this.radiusControl,
    required this.chartLineWidth,
    required this.dataStroke,
    required this.monitorBezel,
  });

  /// Fondo de pantalla (scaffold).
  final Color canvas;

  /// Fondo de tarjeta.
  final Color card;

  /// Filete de la tarjeta. `null` en temas que definen la tarjeta sólo por
  /// contraste con el lienzo.
  final Color? cardBorder;

  /// Elevación de la tarjeta. Lista vacía = tarjeta plana.
  final List<BoxShadow> cardShadow;

  /// Superficie hundida dentro de una tarjeta (casillas de dato, insets).
  final Color inset;

  /// Riel de una barra de progreso o de una escala.
  final Color track;

  /// Separadores y filetes finos.
  final Color divider;

  /// Tinta principal: títulos y cifras.
  final Color ink;

  /// Tinta secundaria: cuerpo y descripciones.
  final Color inkSecondary;

  /// Tinta apagada: etiquetas, unidades, metadatos.
  final Color inkMuted;

  /// Color de marca: cabeceras, splash, acción primaria.
  final Color brand;

  /// Contenido legible sobre [brand].
  final Color onBrand;

  final double radiusCard;
  final double radiusControl;

  /// Grosor de trazo de las series de datos, para que las gráficas hablen el
  /// mismo idioma que el resto del tema.
  final double chartLineWidth;

  /// Color de un trazo de datos dibujado SOBRE [brand] (el electro del arranque).
  final Color dataStroke;

  /// Idioma de componente, en la misma línea que `ClinicalPalette.badgeIdiom`:
  /// si el tema enmarca los trazos de datos en cromo de instrumental —bisel
  /// oscuro, rejilla, resplandor— o los deja desnudos sobre el fondo.
  ///
  /// Es un token y no un `if (temaActual == ...)` dentro de la pantalla a
  /// propósito: ningún widget debe preguntar qué tema está activo, sólo leer
  /// qué le pide el tema.
  final bool monitorBezel;

  BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  BorderRadius get controlRadius => BorderRadius.circular(radiusControl);

  /// Decoración de tarjeta ya montada. Que exista un único sitio donde se
  /// construye evita que cada pantalla reinvente la sombra y el radio, que es
  /// precisamente cómo se acumularon los cientos de colores sueltos que este
  /// sistema viene a ordenar.
  BoxDecoration cardDecoration({double? radius}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radius ?? radiusCard),
    border: cardBorder == null ? null : Border.all(color: cardBorder!),
    boxShadow: cardShadow,
  );

  @override
  AppSurfaces copyWith({
    Color? canvas,
    Color? card,
    Color? cardBorder,
    List<BoxShadow>? cardShadow,
    Color? inset,
    Color? track,
    Color? divider,
    Color? ink,
    Color? inkSecondary,
    Color? inkMuted,
    Color? brand,
    Color? onBrand,
    double? radiusCard,
    double? radiusControl,
    double? chartLineWidth,
    Color? dataStroke,
    bool? monitorBezel,
  }) {
    return AppSurfaces(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      inset: inset ?? this.inset,
      track: track ?? this.track,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusControl: radiusControl ?? this.radiusControl,
      chartLineWidth: chartLineWidth ?? this.chartLineWidth,
      dataStroke: dataStroke ?? this.dataStroke,
      monitorBezel: monitorBezel ?? this.monitorBezel,
    );
  }

  @override
  AppSurfaces lerp(AppSurfaces? other, double t) {
    if (other == null) return this;
    return AppSurfaces(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t),
      cardShadow:
          BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? const [],
      inset: Color.lerp(inset, other.inset, t)!,
      track: Color.lerp(track, other.track, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t),
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t),
      chartLineWidth: lerpDouble(chartLineWidth, other.chartLineWidth, t),
      dataStroke: Color.lerp(dataStroke, other.dataStroke, t)!,
      // Discreto: conmuta a mitad de camino en vez de quedar «medio bisel».
      monitorBezel: t < 0.5 ? monitorBezel : other.monitorBezel,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
