import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/theme/semantic_contract.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/clinical_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';

/// Verifica el CONTRATO SEMÁNTICO contra todos los temas del catálogo.
///
/// Este archivo es lo que convierte «los colores siguen significando lo mismo
/// en cualquier tema» de intención a garantía. Un tema nuevo que apague el
/// ámbar a gris, que vuelva morado el «óptimo» o que deje una insignia por
/// debajo de AA no llega a producción: rompe aquí.
///
/// Se itera sobre `AppThemeCatalog.specs`, no sobre una lista escrita a mano, de
/// modo que añadir un tema lo somete automáticamente a todas las reglas.
void main() {
  const catalog = AppThemeCatalog.specs;

  test('el catálogo no está vacío y no repite identidades ni nombres', () {
    expect(catalog, isNotEmpty);
    expect(
      catalog.map((s) => s.id).toSet().length,
      catalog.length,
      reason: 'Hay dos fichas con el mismo AppThemeId',
    );
    expect(
      catalog.map((s) => s.name).toSet().length,
      catalog.length,
      reason: 'Dos temas comparten nombre visible',
    );
  });

  test('el tema por defecto existe en el catálogo', () {
    expect(
      catalog.any((s) => s.id == AppThemeCatalog.fallback),
      isTrue,
      reason: 'El fallback apunta a un tema que no está registrado',
    );
  });

  test('themeOf memoiza: dos llamadas devuelven la MISMA instancia', () {
    // Si esto falla, cada build del widget raíz reconstruiría la rampa tonal.
    for (final spec in catalog) {
      expect(
        identical(
          AppThemeCatalog.themeOf(spec.id),
          AppThemeCatalog.themeOf(spec.id),
        ),
        isTrue,
        reason: '${spec.name}: ThemeData se está reconstruyendo en cada acceso',
      );
    }
  });

  for (final spec in catalog) {
    group('${spec.name} ·', () {
      final theme = spec.theme;

      test('instala las cuatro extensiones de tokens', () {
        expect(theme.extension<ClinicalPalette>(), isNotNull);
        expect(theme.extension<MetricPalette>(), isNotNull);
        // Los atajos lanzan si falta alguna: basta con que no exploten.
        expect(() => theme.surfaces, returnsNormally);
        expect(() => theme.type, returnsNormally);
      });

      // ── ESTADOS CLÍNICOS ──────────────────────────────────────────────────

      for (final status in kDiagnosticStatuses) {
        final tone = theme.clinical.tone(status);
        final band = SemanticContract.statusHues[status]!;

        test('$status conserva su familia de matiz ($band)', () {
          final hue = SemanticContract.hueOf(tone.accent);
          expect(
            band.contains(hue),
            isTrue,
            reason:
                '${spec.name}: $status está en ${hue.toStringAsFixed(1)}°, '
                'fuera de $band. El usuario aprendió a leer ese color como '
                '"$status" — cambiarle el matiz cambia el significado.',
          );
        });

        test('$status mantiene saturación suficiente', () {
          final sat = SemanticContract.saturationOf(tone.accent);
          expect(
            sat,
            greaterThanOrEqualTo(SemanticContract.minSemanticSaturation),
            reason:
                '${spec.name}: $status tiene saturación '
                '${sat.toStringAsFixed(2)}. Apagado a gris deja de distinguirse '
                'de los demás estados.',
          );
        });

        test('$status es legible en chip suave (acento sobre su tinte)', () {
          final ratio = SemanticContract.contrast(tone.accent, tone.surface);
          expect(
            ratio,
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason:
                '${spec.name}: $status da ${ratio.toStringAsFixed(2)}:1 sobre '
                'su superficie; AA pide ${SemanticContract.minTextContrast}:1 '
                'para el texto pequeño de las insignias.',
          );
        });

        test('$status es legible en chip sólido (texto sobre el acento)', () {
          final ratio = SemanticContract.contrast(tone.onAccent, tone.accent);
          expect(
            ratio,
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason:
                '${spec.name}: $status da ${ratio.toStringAsFixed(2)}:1 para el '
                'texto sobre el relleno sólido.',
          );
        });

        test('$status es legible directamente sobre la tarjeta', () {
          // Cifras y textos de estado se pintan a menudo sobre la tarjeta, sin
          // chip alrededor.
          final ratio = SemanticContract.contrast(
            tone.accent,
            theme.surfaces.card,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason:
                '${spec.name}: $status da ${ratio.toStringAsFixed(2)}:1 sobre '
                'la tarjeta.',
          );
        });
      }

      test('los cuatro estados son mutuamente distinguibles', () {
        for (var i = 0; i < kDiagnosticStatuses.length; i++) {
          for (var j = i + 1; j < kDiagnosticStatuses.length; j++) {
            final a = kDiagnosticStatuses[i];
            final b = kDiagnosticStatuses[j];
            final ha = SemanticContract.hueOf(theme.clinical.tone(a).accent);
            final hb = SemanticContract.hueOf(theme.clinical.tone(b).accent);
            expect(
              SemanticContract.hueDistance(ha, hb),
              greaterThanOrEqualTo(SemanticContract.minFamilyHueSeparation),
              reason: '${spec.name}: $a y $b tienen matices casi idénticos',
            );
          }
        }
      });

      test('la rampa de severidad va de menos a más riesgo', () {
        expect(theme.clinical.severityRamp, hasLength(4));
        expect(
          theme.clinical.severityRamp,
          [
            theme.clinical.info.accent,
            theme.clinical.optimal.accent,
            theme.clinical.caution.accent,
            theme.clinical.alert.accent,
          ],
          reason: 'La rampa debe seguir el orden clínico, no el estético',
        );
      });

      // ── FAMILIAS DE INDICADOR ─────────────────────────────────────────────

      for (final family in MetricFamily.values) {
        final tone = theme.metrics.tone(family);
        final band = SemanticContract.familyHues[family]!;

        test('$family conserva su identidad de matiz ($band)', () {
          final hue = SemanticContract.hueOf(tone.accent);
          expect(
            band.contains(hue),
            isTrue,
            reason:
                '${spec.name}: $family está en ${hue.toStringAsFixed(1)}°, '
                'fuera de $band.',
          );
        });

        test('$family es legible sobre la tarjeta y sobre su tinte', () {
          expect(
            SemanticContract.contrast(tone.accent, theme.surfaces.card),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $family ilegible sobre la tarjeta',
          );
          expect(
            SemanticContract.contrast(tone.accent, tone.surface),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $family ilegible sobre su propio tinte',
          );
          expect(
            SemanticContract.contrast(tone.onAccent, tone.accent),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $family ilegible en relleno sólido',
          );
        });
      }

      test('las cuatro familias se distinguen entre sí', () {
        for (var i = 0; i < MetricFamily.values.length; i++) {
          for (var j = i + 1; j < MetricFamily.values.length; j++) {
            final a = MetricFamily.values[i];
            final b = MetricFamily.values[j];
            final ha = SemanticContract.hueOf(theme.metrics.tone(a).accent);
            final hb = SemanticContract.hueOf(theme.metrics.tone(b).accent);
            expect(
              SemanticContract.hueDistance(ha, hb),
              greaterThanOrEqualTo(SemanticContract.minFamilyHueSeparation),
              reason:
                  '${spec.name}: $a y $b se confundirían de un vistazo '
                  '(${SemanticContract.hueDistance(ha, hb).toStringAsFixed(1)}° '
                  'de separación)',
            );
          }
        }
      });

      // ── CATEGORÍAS DE CONTENIDO ───────────────────────────────────────────

      for (final category in ContentCategory.values) {
        final tone = theme.content.tone(category);
        final band = SemanticContract.contentHues[category]!;

        test('$category conserva su identidad de matiz ($band)', () {
          final hue = SemanticContract.hueOf(tone.accent);
          expect(
            band.contains(hue),
            isTrue,
            reason:
                '${spec.name}: $category está en ${hue.toStringAsFixed(1)}°, '
                'fuera de $band.',
          );
        });

        test('$category es legible sobre la tarjeta y sobre su tinte', () {
          expect(
            SemanticContract.contrast(tone.accent, theme.surfaces.card),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $category ilegible sobre la tarjeta',
          );
          expect(
            SemanticContract.contrast(tone.accent, tone.surface),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $category ilegible sobre su propio tinte',
          );
          expect(
            SemanticContract.contrast(tone.onAccent, tone.accent),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $category ilegible en relleno sólido',
          );
        });
      }

      test('las seis categorías se distinguen entre sí', () {
        for (var i = 0; i < ContentCategory.values.length; i++) {
          for (var j = i + 1; j < ContentCategory.values.length; j++) {
            final a = ContentCategory.values[i];
            final b = ContentCategory.values[j];
            final ha = SemanticContract.hueOf(theme.content.tone(a).accent);
            final hb = SemanticContract.hueOf(theme.content.tone(b).accent);
            expect(
              SemanticContract.hueDistance(ha, hb),
              greaterThanOrEqualTo(SemanticContract.minFamilyHueSeparation),
              reason:
                  '${spec.name}: $a y $b se confundirían de un vistazo '
                  '(${SemanticContract.hueDistance(ha, hb).toStringAsFixed(1)}° '
                  'de separación)',
            );
          }
        }
      });

      test('el nivel de una rutina y el estado de un reto son legibles', () {
        <String, Tone>{
          for (final l in ContentLevelStep.values) '$l': theme.content.level(l),
          for (final s in ContentStatus.values) '$s': theme.content.status(s),
        }.forEach((name, tone) {
          expect(
            SemanticContract.contrast(tone.accent, theme.surfaces.card),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $name ilegible sobre la tarjeta',
          );
          expect(
            SemanticContract.contrast(tone.onAccent, tone.accent),
            greaterThanOrEqualTo(SemanticContract.minTextContrast),
            reason: '${spec.name}: $name ilegible en relleno sólido',
          );
        });
      });

      test('los tres niveles suben de intensidad, no de tono al azar', () {
        // Suave → exigente: verde, ámbar, rojo. Es la convención que el usuario
        // ya conoce de la escala de IMC; lo que se comprueba es que un tema no
        // pueda invertirla.
        final easy = SemanticContract.hueOf(theme.content.levelEasy.accent);
        final medium = SemanticContract.hueOf(theme.content.levelMedium.accent);
        final hard = SemanticContract.hueOf(theme.content.levelHard.accent);
        expect(
          SemanticContract.statusHues[ClinicalStatus.optimal]!.contains(easy),
          isTrue,
          reason: '${spec.name}: «principiante» debería ser verde',
        );
        expect(
          SemanticContract.statusHues[ClinicalStatus.caution]!.contains(medium),
          isTrue,
          reason: '${spec.name}: «intermedio» debería ser ámbar',
        );
        expect(
          SemanticContract.statusHues[ClinicalStatus.alert]!.contains(hard),
          isTrue,
          reason: '${spec.name}: «avanzado» debería ser rojo',
        );
      });

      // ── TINTA Y SUPERFICIES ───────────────────────────────────────────────

      test('las tres tintas son legibles sobre lienzo y tarjeta', () {
        final s = theme.surfaces;
        final inks = {'ink': s.ink, 'inkSecondary': s.inkSecondary};
        for (final entry in inks.entries) {
          for (final bg in {'lienzo': s.canvas, 'tarjeta': s.card}.entries) {
            final ratio = SemanticContract.contrast(entry.value, bg.value);
            expect(
              ratio,
              greaterThanOrEqualTo(SemanticContract.minTextContrast),
              reason:
                  '${spec.name}: ${entry.key} sobre ${bg.key} da '
                  '${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
        // La tinta apagada rotula unidades y metadatos: se le exige el umbral
        // de elemento no textual, no el de texto corrido.
        expect(
          SemanticContract.contrast(s.inkMuted, s.card),
          greaterThanOrEqualTo(SemanticContract.minGraphicContrast),
          reason: '${spec.name}: inkMuted demasiado tenue sobre la tarjeta',
        );
      });

      test('el contenido sobre la marca es legible', () {
        final s = theme.surfaces;
        expect(
          SemanticContract.contrast(s.onBrand, s.brand),
          greaterThanOrEqualTo(SemanticContract.minTextContrast),
          reason: '${spec.name}: onBrand ilegible sobre brand',
        );
      });

      // ── ESTADO SELECCIONADO ───────────────────────────────────────────────
      //
      // El realce de «esto es lo que tienes elegido» se calculaba con un
      // porcentaje fijo de mezcla con la marca. Eso lo hacía depender de lo
      // OSCURA que fuera la marca del tema: claro en «Pulso Clínico», casi
      // invisible en «Consulta Serena», y potencialmente inexistente en un tema
      // futuro con una marca más clara. Estas tres pruebas son la razón por la
      // que ahora es un token y no una cuenta.

      test('el realce de selección se ve sobre la tarjeta', () {
        final s = theme.surfaces;
        final ratio = SemanticContract.contrast(s.selection, s.card);
        expect(
          ratio,
          greaterThanOrEqualTo(SemanticContract.minSelectionStep),
          reason:
              '${spec.name}: `selection` da ${ratio.toStringAsFixed(3)}:1 sobre '
              'la tarjeta. Por debajo de ${SemanticContract.minSelectionStep} '
              'el usuario no ve qué pestaña o fila tiene elegida.',
        );
      });

      test('el realce de selección se ve sobre el lienzo', () {
        final s = theme.surfaces;
        // En el lienzo el realce puede ser más tenue —ahí suele acompañarlo un
        // cambio de color de icono y texto—, pero no puede ser el propio lienzo.
        expect(
          s.selection,
          isNot(equals(s.canvas)),
          reason: '${spec.name}: `selection` es idéntico al lienzo',
        );
        expect(
          s.selection,
          isNot(equals(s.card)),
          reason: '${spec.name}: `selection` es idéntico a la tarjeta',
        );
      });

      test('el realce de selección no tapa el contenido que lleva encima', () {
        final s = theme.surfaces;
        // Sobre el realce se pintan el icono y el rótulo del elemento elegido.
        // Es texto pequeño —9 px en la barra—, así que le toca el umbral de
        // texto, no el de gráfico.
        final ratio = SemanticContract.contrast(s.onSelection, s.selection);
        expect(
          ratio,
          greaterThanOrEqualTo(SemanticContract.minTextContrast),
          reason:
              '${spec.name}: onSelection sobre selection da '
              '${ratio.toStringAsFixed(2)}:1',
        );
      });

      test(
        'onSelection no se aleja de la marca: sigue siendo el mismo color',
        () {
          final s = theme.surfaces;
          // El par existe para resolver contraste, no para que un tema meta un
          // color nuevo por la puerta de atrás: el realce tiene que seguir
          // leyéndose como «la marca», no como otra cosa.
          final d = SemanticContract.hueDistance(
            SemanticContract.hueOf(s.onSelection),
            SemanticContract.hueOf(s.brand),
          );
          expect(
            d,
            lessThanOrEqualTo(SemanticContract.minFamilyHueSeparation),
            reason:
                '${spec.name}: onSelection está a ${d.toStringAsFixed(1)}° de la '
                'marca; debería ser un paso del mismo color, no otro.',
          );
        },
      );

      test('la tarjeta se separa del lienzo por color o por sombra', () {
        final s = theme.surfaces;
        final separable =
            s.card != s.canvas ||
            s.cardShadow.isNotEmpty ||
            s.cardBorder != null;
        expect(
          separable,
          isTrue,
          reason: '${spec.name}: la tarjeta sería invisible sobre el lienzo',
        );
      });

      // ── TIPOGRAFÍA ────────────────────────────────────────────────────────

      test('todo rol tipográfico define familia y tamaño', () {
        final t = theme.type;
        <String, TextStyle>{
          'display': t.display,
          'displayMeta': t.displayMeta,
          'screenTitle': t.screenTitle,
          'cardTitle': t.cardTitle,
          'sectionLabel': t.sectionLabel,
          'fieldLabel': t.fieldLabel,
          'numeral': t.numeral,
          'numeralSmall': t.numeralSmall,
          'numeralUnit': t.numeralUnit,
          'body': t.body,
          'meta': t.meta,
          'badge': t.badge,
          'button': t.button,
        }.forEach((name, style) {
          expect(
            style.fontFamily,
            isNotNull,
            reason: '${spec.name}: el rol $name no fija familia',
          );
          expect(
            style.fontSize,
            isNotNull,
            reason: '${spec.name}: el rol $name no fija tamaño',
          );
          expect(
            style.fontSize,
            greaterThanOrEqualTo(10),
            reason: '${spec.name}: el rol $name baja de 10 px',
          );
        });
      });

      test('la cifra protagonista domina sobre el texto corrido', () {
        // Jerarquía mínima: si el número no manda, la tarjeta no se lee de un
        // vistazo, que es el único trabajo que tiene.
        expect(
          theme.type.numeral.fontSize,
          greaterThan(theme.type.body.fontSize!),
          reason: '${spec.name}: numeral no destaca sobre body',
        );
      });
    });
  }

  // ── TRANSICIÓN ENTRE TEMAS ─────────────────────────────────────────────────

  group('interpolación entre temas ·', () {
    test('lerp a mitad de camino no produce nulos ni excepciones', () {
      // AnimatedTheme interpola las extensiones; si un lerp explotara, el
      // cambio de tema reventaría a mitad de animación.
      for (final a in AppThemeCatalog.specs) {
        for (final b in AppThemeCatalog.specs) {
          for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
            final clinical = a.theme.clinical.lerp(b.theme.clinical, t);
            expect(clinical.tone(ClinicalStatus.alert).accent, isNotNull);

            final metrics = a.theme.metrics.lerp(b.theme.metrics, t);
            expect(metrics.tone(MetricFamily.vitals).accent, isNotNull);

            final surfaces = a.theme.surfaces.lerp(b.theme.surfaces, t);
            expect(surfaces.radiusCard, greaterThan(0));
            expect(surfaces.chartLineWidth, greaterThan(0));

            final type = a.theme.type.lerp(b.theme.type, t);
            expect(type.numeral.fontSize, isNotNull);
            expect(type.cardTitle.fontSize, isNotNull);
          }
        }
      }
    });

    test('lerp con null devuelve el original (contrato de ThemeExtension)', () {
      final theme = AppThemeCatalog.themeOf(AppThemeId.consultaSerena);
      expect(theme.clinical.lerp(null, 0.5), same(theme.clinical));
      expect(theme.metrics.lerp(null, 0.5), same(theme.metrics));
      expect(theme.surfaces.lerp(null, 0.5), same(theme.surfaces));
      expect(theme.type.lerp(null, 0.5), same(theme.type));
    });
  });
}
