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

    required this.selection,

    required this.onSelection,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.brand,
    required this.onBrand,
    required this.radiusCard,
    required this.radiusControl,
    required this.radiusSelection,
    required this.radiusIcon,
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

  /// Relleno que marca algo como ELEGIDO o agrupado: la pestaña activa de la
  /// barra, la fila del menú de ajustes, el idioma seleccionado.
  ///
  /// Existe porque antes cada sitio lo improvisaba con `Color.lerp(card, brand,
  /// 0.08)` y variantes. Ese porcentaje fijo NO da el mismo escalón en todos los
  /// temas: mezclar un 8 % de un azul oscuro aparta el blanco mucho más que un
  /// 8 % de un verde medio, así que el mismo código dibujaba un realce claro en
  /// «Pulso Clínico» y algo casi invisible en «Consulta Serena». El tema tiene
  /// que ELEGIR este color, no heredarlo de un accidente aritmético, y el
  /// contrato semántico comprueba que se distinga de la tarjeta y del lienzo.
  final Color selection;

  /// Contenido —icono y rótulo— que se dibuja ENCIMA de [selection].
  ///
  /// Va en par con él por la misma razón que [Tone] lleva `accent` y `onAccent`
  /// juntos: hacer el realce más visible oscurece el fondo, y eso baja el
  /// contraste de lo que lleva encima. Las dos exigencias chocan si un tema
  /// tiene la marca clara — el salvia de «Consulta Serena» da 4,79:1 sobre
  /// blanco, así que cualquier tinte la deja por debajo de AA—. Con el par, cada
  /// tema resuelve su propio compromiso en vez de heredar el de otro.
  final Color onSelection;

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

  /// Redondeo del RELLENO QUE MARCA LO ELEGIDO: el fondo de la pestaña activa
  /// de la barra, la fila de ajustes seleccionada, el idioma en uso. Es el
  /// compañero de FORMA del color [selection], igual que [onSelection] es su
  /// compañero de CONTENIDO.
  ///
  /// Es siempre un rectángulo redondeado, NUNCA una cápsula ni un círculo, y por
  /// eso NO hereda de [radiusControl]. Ese es el radio del botón, y un tema es
  /// libre de hacer sus botones en cápsula —«Pulso Clínico» los pone en 30—. La
  /// barra tomaba de ahí la forma del realce, así que sobre un indicador alto ese
  /// 30 lo redondeaba hasta leerse como círculo en un tema y como rectángulo en
  /// otro: la misma pantalla se veía distinta según el tema. Al tener su propio
  /// token, la forma del realce la decide este contrato —acotado a rectángulo por
  /// su prueba— y no un accidente del idioma de botón de cada tema.
  final double radiusSelection;

  /// Redondeo de la CAJA QUE ENCIERRA UN ICONO: la pastilla de color detrás del
  /// icono de una fila, de una tarjeta o de una cabecera.
  ///
  /// Es un cuadrado redondeado, nunca un círculo, y es el mismo gesto en toda la
  /// app. Existía disperso: el menú de Historial dibujaba su caja con un
  /// `BorderRadius.circular(10)` escrito a mano y la hoja de «Registrar
  /// indicadores» dibujaba la suya con `shape: BoxShape.circle`, así que dos
  /// listas con la misma anatomía —icono, rótulo, chevron— se veían distintas
  /// según por dónde se entrara. Al ser un token, cada tema decide cuánto
  /// redondea su caja y ninguna pantalla vuelve a inventarse la forma.
  final double radiusIcon;

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
  BorderRadius get selectionRadius => BorderRadius.circular(radiusSelection);
  BorderRadius get iconRadius => BorderRadius.circular(radiusIcon);

  /// Halo de color alrededor de un elemento destacado: el botón elegido, la
  /// tarjeta en primer plano.
  ///
  /// **Devuelve una lista vacía en los temas planos.** Esa es toda la razón de
  /// que exista: media app escribía su halo a mano con un `BoxShadow(...)`, y
  /// un `BoxShadow` escrito a mano no sabe si el tema levanta las cosas del
  /// lienzo o las deja planas. El resultado era que «Consulta Serena» —que no
  /// tiene ni una sombra en sus tarjetas— sí las tenía sueltas por dentro, y no
  /// había forma de notarlo salvo mirando pantalla por pantalla.
  List<BoxShadow> glow(
    Color color, {
    double alpha = 0.25,
    double blur = 12,
    Offset offset = const Offset(0, 4),
  }) {
    if (cardShadow.isEmpty) return const [];
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

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

    Color? selection,

    Color? onSelection,
    Color? ink,
    Color? inkSecondary,
    Color? inkMuted,
    Color? brand,
    Color? onBrand,
    double? radiusCard,
    double? radiusControl,
    double? radiusSelection,
    double? radiusIcon,
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

      selection: selection ?? this.selection,

      onSelection: onSelection ?? this.onSelection,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusControl: radiusControl ?? this.radiusControl,
      radiusSelection: radiusSelection ?? this.radiusSelection,
      radiusIcon: radiusIcon ?? this.radiusIcon,
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

      selection: Color.lerp(selection, other.selection, t)!,

      onSelection: Color.lerp(onSelection, other.onSelection, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t),
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t),
      radiusSelection: lerpDouble(radiusSelection, other.radiusSelection, t),
      radiusIcon: lerpDouble(radiusIcon, other.radiusIcon, t),
      chartLineWidth: lerpDouble(chartLineWidth, other.chartLineWidth, t),
      dataStroke: Color.lerp(dataStroke, other.dataStroke, t)!,
      // Discreto: conmuta a mitad de camino en vez de quedar «medio bisel».
      monitorBezel: t < 0.5 ? monitorBezel : other.monitorBezel,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
