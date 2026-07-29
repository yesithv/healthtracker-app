import 'package:flutter/material.dart';

import '../tokens/app_surfaces.dart';
import '../tokens/app_typography.dart';
import '../tokens/clinical_palette.dart';
import '../tokens/content_palette.dart';
import '../tokens/metric_palette.dart';
import '../tokens/tone.dart';
import 'type_scale.dart';

/// «CONSULTA SERENA» — dirección 1b del sistema de diseño de My Vitals.
///
/// Carácter: lienzo cálido, tarjetas blancas planas y amplias, cifras en serif
/// (Newsreader), interfaz en IBM Plex Sans y etiquetas en IBM Plex Mono.
/// Insignias de estado en relleno suave. Menos densidad y menos ruido: una
/// lectura por tarjeta, silencio alrededor del dato.
///
/// Donde «Pulso Clínico» informa, este tema tranquiliza — sin renunciar a nada:
/// la misma navegación, los mismos iconos, la misma maqueta y exactamente los
/// mismos significados de color.
class ConsultaSerena {
  const ConsultaSerena._();

  // ── Paleta base del sistema ───────────────────────────────────────────────
  static const Color _salvia = Color(0xFF5F7A4E); // marca
  static const Color _lienzo = Color(0xFFEFEEE9); // fondo
  static const Color _tinta = Color(0xFF24271F); // tinta principal
  static const Color _tarjeta = Color(0xFFFFFFFF);
  // Blanco cálido del propio sistema de diseño. Se usa #FBFAF8 y no el
  // #F3F5EF de la lámina porque sobre salvia éste daba 4,36:1 y la etiqueta del
  // botón primario (15 px semibold) es texto pequeño para WCAG: necesita 4,5:1.
  // La diferencia a ojo es inapreciable; la de legibilidad, no.
  static const Color _onSalvia = Color(0xFFFBFAF8);

  // #6E7275 en la lámina. Sobre la tarjeta blanca cumplía (4,85:1), pero sobre
  // el lienzo cálido caía a 4,18:1, y el cuerpo de texto va sobre lienzo tan a
  // menudo como sobre tarjeta. Oscurecido lo justo para cumplir en ambos.
  static const Color _inkSecondary = Color(0xFF63676A);
  static const Color _inkMuted = Color(0xFF8B9080);

  // ── Tipografías ───────────────────────────────────────────────────────────
  static const String _serif = 'Newsreader'; // cifras y titulares
  static const String _sans = 'IBM Plex Sans'; // interfaz y cuerpo
  static const String _mono = 'IBM Plex Mono'; // etiquetas, unidades, rangos

  /// Trazo claro para series de datos sobre fondo salvia (el ECG del arranque).
  static const Color ecgStroke = Color(0xFFCBD8BE);

  /// Mezcla del acento con la tarjeta para derivar su tinte suave. Ver la nota
  /// equivalente en «Pulso Clínico»: al 8 % el acento sobre su propio tinte
  /// supera AA con margen.
  static const double _tint = 0.08;

  static ThemeData build() {
    const surfaces = AppSurfaces(
      canvas: _lienzo,
      card: _tarjeta,
      // Tarjetas PLANAS y sin filete: el contraste con el lienzo cálido basta
      // para separarlas, y quitar la sombra es la mitad de la calma del tema.
      cardBorder: null,
      cardShadow: [],
      inset: Color(0xFFF4F5F0),
      track: Color(0xFFEDEFE9),
      divider: Color(0xFFE4E1DB),
      // Elegido: salvia al 16 % sobre la tarjeta. Hace falta más mezcla que en
      // «Pulso Clínico» porque el salvia es más claro que su azul; con el mismo
      // 8 % el realce se perdía. Ese es justo el accidente que el token evita.
      selection: Color(0xFFE5EAE3),
      // El salvia de marca daría 3,9:1 sobre este tinte: aquí va un paso más
      // profundo del mismo verde, que llega a 5,8:1 sin cambiar de familia.
      onSelection: Color(0xFF46603A),
      ink: _tinta,
      inkSecondary: _inkSecondary,
      inkMuted: _inkMuted,
      brand: _salvia,
      onBrand: _onSalvia,
      radiusCard: 20,
      radiusControl: 14,
      // Un punto más blando que «Pulso Clínico», en la misma línea que el
      // resto del tema, pero sigue siendo un cuadrado.
      radiusIcon: 14,
      chartLineWidth: 2.5,
      dataStroke: ecgStroke,
      monitorBezel: false,
    );

    // Estados clínicos, tal como los define el sistema de diseño.
    //
    // Dos ajustes respecto al documento, ambos para no perder información:
    //
    // · «Bajo» aparecía en gris neutro. Pero `info` significa «por debajo de
    //   rango»: es un hallazgo clínico, no una casilla vacía, y pintarlo igual
    //   que lo no-valorado lo hacía desaparecer. Se usa un azul pizarra
    //   apagado que encaja en la gama terrosa y conserva la convención de
    //   «frío = bajo» que el usuario ya tiene aprendida.
    // · El gris del chip neutro se ha oscurecido de #6E7275 a #5E6265: sobre
    //   su propio tinte, el original daba 4,1:1 y no llegaba a AA. #6E7275 se
    //   mantiene intacto como tinta secundaria, donde va sobre blanco y cumple.
    const clinical = ClinicalPalette(
      badgeIdiom: BadgeIdiom.soft,
      info: Tone(
        accent: Color(0xFF4A5D6E),
        surface: Color(0xFFE4E9ED),
        onAccent: _onSalvia,
      ),
      optimal: Tone(
        accent: Color(0xFF3D6B4A), // «Óptimo»
        surface: Color(0xFFE6EFE3),
        onAccent: _onSalvia,
      ),
      caution: Tone(
        accent: Color(0xFF8A5F16), // «Atención»
        surface: Color(0xFFF6EEDD),
        onAccent: _onSalvia,
      ),
      alert: Tone(
        accent: Color(0xFFA04A3C), // «Alto»
        surface: Color(0xFFF6E5E1),
        onAccent: _onSalvia,
      ),
      neutral: Tone(
        accent: Color(0xFF5E6265),
        surface: Color(0xFFECEDE8),
        onAccent: _onSalvia,
      ),
    );

    // Familias de indicador armonizadas a la gama terrosa del tema. El matiz
    // de cada una se conserva —rojo el corazón, ámbar la medida corporal, verde
    // azulado el laboratorio, índigo la estructura—; lo que baja es el volumen.
    const metrics = MetricPalette(
      vitals: Tone(
        accent: Color(0xFFA04A3C),
        surface: Color(0xFFF6E5E1),
        onAccent: _onSalvia,
      ),
      anthropometry: Tone(
        accent: Color(0xFF8A5F16),
        surface: Color(0xFFF6EEDD),
        onAccent: _onSalvia,
      ),
      lipids: Tone(
        accent: Color(0xFF2F6B63),
        surface: Color(0xFFDDEAE7),
        onAccent: _onSalvia,
      ),
      bodyComposition: Tone(
        accent: Color(0xFF4F5B7A),
        surface: Color(0xFFE4E7EF),
        onAccent: _onSalvia,
      ),
    );

    // Categorías editoriales de «Descubre», apagadas hacia tierra como el resto
    // del tema. Se conserva la FAMILIA DE MATIZ de cada una —el corazón sigue
    // siendo rojo, el sueño sigue siendo índigo— porque el usuario las reconoce
    // por el color; lo que baja es el volumen. Varias comparten matiz con su
    // familia de indicador a propósito: un artículo del corazón y la tarjeta de
    // signos vitales hablan de lo mismo.
    final content = ContentPalette(
      heart: Tone.from(
        const Color(0xFFA04A3C),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      nutrition: Tone.from(
        const Color(0xFF4C6B3C),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      emotional: Tone.from(
        const Color(0xFF6B5075),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      sports: Tone.from(
        const Color(0xFF8A5F16),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      sleep: Tone.from(
        const Color(0xFF4F5B7A),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      daily: Tone.from(
        const Color(0xFF2F6B63),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      levelEasy: Tone.from(
        const Color(0xFF3D6B4A),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      levelMedium: Tone.from(
        const Color(0xFF8A5F16),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      levelHard: Tone.from(
        const Color(0xFFA04A3C),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      statusActive: Tone.from(
        const Color(0xFF3D6B4A),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      statusScheduled: Tone.from(
        const Color(0xFF2F6B63),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
      statusClosed: Tone.from(
        const Color(0xFF63676A),
        canvas: _tarjeta,
        onAccent: _onSalvia,
        surfaceBlend: _tint,
      ),
    );

    final typography = AppTypography(
      // Logotipo: Newsreader ligera, sin versalitas ni tracking forzado.
      display: TypeScale.variable(
        _serif,
        size: 40,
        weight: 300,
        letterSpacing: 0.4,
      ),
      displayMeta: TypeScale.static_(
        _sans,
        size: TypeScale.md,
        weight: FontWeight.w400,
      ),
      screenTitle: TypeScale.variable(
        _serif,
        size: TypeScale.xxl,
        weight: 400,
        color: _tinta,
        height: 1.15,
      ),
      // Título de tarjeta: IBM Plex Sans 600 en caja mixta, como la lámina.
      cardTitle: TypeScale.static_(
        _sans,
        size: 14,
        weight: FontWeight.w600,
        color: _tinta,
      ),
      // Rótulos de sección en monoespaciada y versalitas: el gesto que más
      // define el tema. Las mayúsculas las aplica el widget de rótulo.
      sectionLabel: TypeScale.static_(
        _mono,
        size: 10,
        weight: FontWeight.w600,
        color: _inkMuted,
        letterSpacing: 1.6,
      ),
      fieldLabel: TypeScale.static_(
        _mono,
        size: TypeScale.sm,
        weight: FontWeight.w400,
        color: _inkMuted,
        letterSpacing: 1.2,
      ),
      numeral: TypeScale.variable(
        _serif,
        size: TypeScale.display,
        weight: 400,
        color: _tinta,
        height: 1.0,
      ),
      numeralSmall: TypeScale.variable(
        _serif,
        size: 28,
        weight: 400,
        color: _tinta,
        height: 1.0,
      ),
      numeralUnit: TypeScale.static_(
        _mono,
        size: TypeScale.xs,
        weight: FontWeight.w400,
        color: _inkMuted,
      ),
      body: TypeScale.static_(
        _sans,
        size: TypeScale.base,
        weight: FontWeight.w400,
        color: _inkSecondary,
        height: 1.55,
      ),
      // Ejemplo dentro de un campo vacío: mismo cuerpo que lo que se teclea
      // —para que no salte el texto al escribir— pero en cursiva y apagado.
      //
      // NO usa `_inkMuted`: ese verde grisáceo da 2,99:1 sobre el hundido del
      // campo, justo por debajo del 3:1 que hace falta para leerlo. Un
      // ejemplo que no se lee no sirve de ejemplo. Éste es el mismo tono, dos
      // pasos más oscuro: 3,29:1 sobre el hundido y aún 3,58:1 de separación
      // con la tinta, que es lo que lo delata como ejemplo y no como dato.
      hint: TypeScale.static_(
        _sans,
        size: TypeScale.base,
        weight: FontWeight.w400,
        color: const Color(0xFF848977),
        height: 1.55,
      ).copyWith(fontStyle: FontStyle.italic),
      meta: TypeScale.static_(
        _sans,
        size: TypeScale.sm,
        weight: FontWeight.w400,
        color: _inkMuted,
      ),
      badge: TypeScale.static_(
        _sans,
        size: TypeScale.xs,
        weight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      button: TypeScale.static_(
        _sans,
        size: TypeScale.base,
        weight: FontWeight.w600,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: _sans,
      scaffoldBackgroundColor: surfaces.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _salvia,
        primary: _salvia,
        surface: _tarjeta,
        error: clinical.alert.accent,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _sans,
        bodyColor: _tinta,
        displayColor: _tinta,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: typography.hint,
      ),
      extensions: [surfaces, clinical, metrics, content, typography],
    );
  }
}
