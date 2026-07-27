import 'package:flutter/material.dart';

import '../tokens/app_surfaces.dart';
import '../tokens/app_typography.dart';
import '../tokens/clinical_palette.dart';
import '../tokens/content_palette.dart';
import '../tokens/metric_palette.dart';
import '../tokens/tone.dart';
import 'type_scale.dart';

/// «PULSO CLÍNICO» — el tema histórico de My Vitals, ahora con nombre.
///
/// Carácter: azul clínico profundo, tarjetas blancas que flotan sobre un gris
/// azulado, Inter en todos los pesos, insignias de estado en relleno sólido.
/// Es un tema enérgico y denso, de aire hospitalario: mucha información a la
/// vista, jerarquía marcada por el peso de la tipografía.
///
/// Reproduce el aspecto que la app ya tenía, con UNA desviación deliberada:
/// los colores de estado e indicador se han oscurecido a su paso equivalente
/// más profundo (mismo matiz, más densidad). El original —verde #10B981, ámbar
/// #F59E0B, rojo #EF4444— daba entre 2,4:1 y 3,8:1 sobre sus fondos, por debajo
/// del 4,5:1 que WCAG AA exige para texto pequeño; las insignias de 10 px eran
/// difíciles de leer. Los valores nuevos superan el umbral conservando la
/// familia de matiz, así que el tema se reconoce igual pero ya es legible.
class PulsoClinico {
  const PulsoClinico._();

  // ── Marca ─────────────────────────────────────────────────────────────────
  static const Color _brand = Color(0xFF0D48A0);
  static const Color _canvas = Color(0xFFF4F6F9);
  static const Color _card = Color(0xFFFFFFFF);

  // ── Tinta ─────────────────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF1E293B);

  // Era #64748B. Sobre el lienzo gris azulado daba 4,40:1, justo por debajo del
  // 4,5:1 de AA para texto pequeño. Mismo matiz pizarra, un paso más profundo.
  static const Color _inkSecondary = Color(0xFF5C6B82);

  // Era #94A3B8: 2,56:1 sobre la tarjeta, por debajo incluso del 3:1 mínimo
  // para elementos no textuales. Rotula las unidades («mmHg», «bpm», «kg»), que
  // es justo el texto que uno necesita leer para interpretar la cifra de al lado.
  static const Color _inkMuted = Color(0xFF7C8CA3);

  /// Mezcla del acento con la tarjeta para derivar su tinte suave. Al 12 % el
  /// tinte queda tan oscuro que el propio acento encima se queda en 4,3–4,5:1,
  /// justo por debajo de AA; al 8 % pasa con margen y el chip se sigue leyendo
  /// como del mismo color. Lo verifica el contrato semántico.
  static const double _tint = 0.08;

  static const String _ui = 'Inter';

  static ThemeData build() {
    const surfaces = AppSurfaces(
      canvas: _canvas,
      card: _card,
      cardBorder: null, // la tarjeta se define por su sombra, no por filete
      cardShadow: [
        BoxShadow(
          color: Color(0x0A000000), // negro al 4 %
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
      inset: Color(0xFFF8FAFC),
      track: Color(0xFFE2E8F0),
      divider: Color(0xFFE2E8F0),
      // Elegido: azul de marca al 11 % sobre la tarjeta. No es «brand al 8 %»
      // como antes: el porcentaje se eligió para que el escalón se vea, y el
      // contrato comprueba que se vea también en cualquier tema nuevo.
      selection: Color(0xFFE4EBF5),
      // La marca aguanta de sobra sobre su propio tinte (7,1:1).
      onSelection: Color(0xFF0D48A0),
      ink: _ink,
      inkSecondary: _inkSecondary,
      inkMuted: _inkMuted,
      brand: _brand,
      onBrand: Color(0xFFFFFFFF),
      radiusCard: 20,
      radiusControl: 30, // cápsulas: el idioma de botón que ya usaba la app
      chartLineWidth: 3,
      dataStroke: Color(0xFF22C55E), // verde fósforo del monitor
      monitorBezel: true,
    );

    // Estados clínicos. Matiz idéntico al original, densidad subida al paso
    // 700 para cumplir AA tanto en relleno sólido (texto blanco encima) como
    // en chip suave (texto del acento sobre su tinte).
    const clinical = ClinicalPalette(
      badgeIdiom: BadgeIdiom.solid,
      info: Tone(
        accent: Color(0xFF1D4ED8), // azul 700
        surface: Color(0xFFEFF6FF),
        onAccent: Color(0xFFFFFFFF),
      ),
      optimal: Tone(
        accent: Color(0xFF047857), // esmeralda 700
        surface: Color(0xFFF0FDF4),
        onAccent: Color(0xFFFFFFFF),
      ),
      caution: Tone(
        accent: Color(0xFFB45309), // ámbar 700
        surface: Color(0xFFFFFBEB),
        onAccent: Color(0xFFFFFFFF),
      ),
      alert: Tone(
        accent: Color(0xFFB91C1C), // rojo 700
        surface: Color(0xFFFEF2F2),
        onAccent: Color(0xFFFFFFFF),
      ),
      neutral: Tone(
        accent: Color(0xFF52525B),
        surface: Color(0xFFF4F4F5),
        onAccent: Color(0xFFFFFFFF),
      ),
    );

    // Familias de indicador: los matices que la app ya usaba (rojo, ámbar,
    // teal, índigo), oscurecidos por el mismo motivo de contraste.
    const metrics = MetricPalette(
      vitals: Tone(
        accent: Color(0xFFC62828),
        surface: Color(0xFFFFEBEE),
        onAccent: Color(0xFFFFFFFF),
      ),
      anthropometry: Tone(
        accent: Color(0xFF9A4E00),
        surface: Color(0xFFFFF3E0),
        onAccent: Color(0xFFFFFFFF),
      ),
      lipids: Tone(
        accent: Color(0xFF00695C),
        surface: Color(0xFFE0F2F1),
        onAccent: Color(0xFFFFFFFF),
      ),
      bodyComposition: Tone(
        accent: Color(0xFF3949AB),
        surface: Color(0xFFE8EAF6),
        onAccent: Color(0xFFFFFFFF),
      ),
    );

    // Categorías editoriales de «Descubre». Conserva los seis matices que la
    // sección ya usaba —vivos, porque este tema es enérgico—, con las
    // superficies derivadas del lienzo en vez de escritas a mano.
    final content = ContentPalette(
      heart: Tone.from(
        const Color(0xFFC2373C),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      nutrition: Tone.from(
        const Color(0xFF127A38),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      emotional: Tone.from(
        const Color(0xFF7E22CE),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      sports: Tone.from(
        const Color(0xFFB34700),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      sleep: Tone.from(
        const Color(0xFF4338CA),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      daily: Tone.from(
        const Color(0xFF0F766E),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      // Intensidad de una rutina. Comparte matices con la rampa de severidad
      // por convención visual (suave → exigente), no por significado clínico.
      levelEasy: Tone.from(
        const Color(0xFF127A38),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      levelMedium: Tone.from(
        const Color(0xFFB45309),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      levelHard: Tone.from(
        const Color(0xFFC2373C),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      statusActive: Tone.from(
        const Color(0xFF127A38),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      statusScheduled: Tone.from(
        const Color(0xFF0F766E),
        canvas: _card,
        surfaceBlend: _tint,
      ),
      statusClosed: Tone.from(
        const Color(0xFF5C6B82),
        canvas: _card,
        surfaceBlend: _tint,
      ),
    );

    final typography = AppTypography(
      display: TypeScale.variable(_ui, size: 32, weight: 700, letterSpacing: 4),
      displayMeta: TypeScale.variable(
        _ui,
        size: TypeScale.lg,
        weight: 500,
        letterSpacing: 2,
      ),
      screenTitle: TypeScale.variable(
        _ui,
        size: TypeScale.xxl,
        weight: 700,
        color: _ink,
        height: 1.2,
      ),
      cardTitle: TypeScale.variable(
        _ui,
        size: TypeScale.sm,
        weight: 700,
        color: _ink,
        letterSpacing: 1.0,
      ),
      sectionLabel: TypeScale.variable(
        _ui,
        size: TypeScale.sm,
        weight: 700,
        color: _ink,
        letterSpacing: 1.0,
      ),
      fieldLabel: TypeScale.variable(
        _ui,
        size: TypeScale.md,
        weight: 600,
        color: _inkSecondary,
      ),
      numeral: TypeScale.variable(
        _ui,
        size: 26,
        weight: 700,
        color: _ink,
        height: 1.1,
      ),
      numeralSmall: TypeScale.variable(
        _ui,
        size: TypeScale.xl,
        weight: 700,
        color: _ink,
        height: 1.1,
      ),
      numeralUnit: TypeScale.variable(
        _ui,
        size: TypeScale.xs,
        weight: 700,
        color: _inkMuted,
      ),
      body: TypeScale.variable(
        _ui,
        size: TypeScale.base,
        weight: 400,
        color: _inkSecondary,
        height: 1.5,
      ),
      meta: TypeScale.variable(
        _ui,
        size: TypeScale.sm,
        weight: 400,
        color: _inkMuted,
      ),
      badge: TypeScale.variable(_ui, size: 10, weight: 700, letterSpacing: 0.3),
      button: TypeScale.variable(
        _ui,
        size: TypeScale.md,
        weight: 700,
        letterSpacing: 0.3,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: _ui,
      scaffoldBackgroundColor: surfaces.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brand,
        primary: _brand,
        surface: surfaces.card,
        error: clinical.alert.accent,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      extensions: [surfaces, clinical, metrics, content, typography],
    );
  }

  /// Reescribe el [TextTheme] de Material en la familia del tema. Es la red de
  /// seguridad para los widgets que aún no leen roles: si algo usa
  /// `bodyMedium`, al menos sale en la tipografía correcta.
  static TextTheme _textTheme(TextTheme base) {
    return base.apply(fontFamily: _ui, bodyColor: _ink, displayColor: _ink);
  }
}
