// UN TEXTO DE EJEMPLO TIENE QUE PARECER UN EJEMPLO.
//
// En el alta, `email@ejemplo.com` y `300 123 4567` se leían como datos ya
// escritos: salían en el gris por defecto de Material, del mismo tamaño y del
// mismo corte que lo que teclea el usuario. La gente daba por rellenos campos
// que estaban vacíos y seguía adelante sin poner su correo.
//
// El arreglo no es un color más claro en una pantalla, sino un rol —
// `type.hint`— que cada tema define y que el `inputDecorationTheme` aplica a
// TODOS los campos de la app. Esta prueba comprueba que ningún tema, ni los que
// vengan, pueda dejar el ejemplo indistinguible del dato:
//
//   1. Va en cursiva. Es la señal que no depende del color, y por tanto la que
//      sigue funcionando con una pantalla al sol o una vista que no separa
//      bien los grises.
//   2. Es más claro que la tinta, con un escalón medible. La cursiva sola
//      tampoco basta: hay tipografías donde apenas se aprecia.
//   3. Mide lo mismo que el texto normal, para que la línea no dé un salto en
//      cuanto se escribe la primera letra.
//   4. Sigue siendo legible. Un ejemplo que no se lee no es un ejemplo: se
//      exige el 3:1 de AA para texto grande, no el 4.5:1 del texto normal,
//      porque es una pista y no contenido.
//   5. El tema lo aplica de oficio a todos los campos.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Sobre el catálogo, no sobre una lista escrita a mano: un tema nuevo entra
  // en esta prueba por el hecho de existir.
  for (final spec in AppThemeCatalog.specs) {
    final theme = AppThemeCatalog.themeOf(spec.id);
    final type = theme.type;
    final surfaces = theme.surfaces;
    final hint = type.hint;

    group('«${spec.name}» · el ejemplo de un campo', () {
      test('va en cursiva', () {
        expect(
          hint.fontStyle,
          FontStyle.italic,
          reason:
              'La cursiva es la única señal que sobrevive a un contraste malo. '
              'Sin ella, el ejemplo depende de que el usuario distinga dos '
              'grises.',
        );
      });

      test('es más claro que la tinta, y se nota', () {
        final hintColor = hint.color!;
        final step = _contrast(surfaces.ink, hintColor);
        expect(
          step,
          greaterThan(1.6),
          reason:
              'El ejemplo (${hintColor.toARGB32().toRadixString(16)}) y la '
              'tinta (${surfaces.ink.toARGB32().toRadixString(16)}) se '
              'diferencian ${step.toStringAsFixed(2)}:1. Por debajo de 1,6:1 '
              'son el mismo gris a ojo y el ejemplo vuelve a leerse como un '
              'dato escrito.',
        );
      });

      test('mide lo mismo que el texto que se teclea', () {
        expect(
          hint.fontSize,
          type.body.fontSize,
          reason:
              'Si el ejemplo mide distinto que el texto, la línea da un salto '
              'al escribir la primera letra.',
        );
      });

      test('sigue siendo legible sobre el fondo del campo', () {
        // El campo se pinta sobre `inset` en los formularios y sobre `card` en
        // los buscadores; tiene que aguantar en ambos.
        for (final background in {
          'inset': surfaces.inset,
          'card': surfaces.card,
        }.entries) {
          final ratio = _contrast(hint.color!, background.value);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                'Sobre «${background.key}» el ejemplo da '
                '${ratio.toStringAsFixed(2)}:1. Un ejemplo que no se lee no '
                'sirve de ejemplo.',
          );
        }
      });

      test('el tema lo aplica a todos los campos, sin pedirlo pantalla a '
          'pantalla', () {
        expect(
          theme.inputDecorationTheme.hintStyle,
          isNotNull,
          reason:
              'Sin `inputDecorationTheme.hintStyle`, cada campo nuevo vuelve '
              'a salir con el gris por defecto de Material y hay que acordarse '
              'de arreglarlo uno a uno.',
        );
        expect(
          theme.inputDecorationTheme.hintStyle!.fontStyle,
          FontStyle.italic,
        );
        expect(theme.inputDecorationTheme.hintStyle!.color, hint.color);
      });
    });
  }

  test('ninguna pantalla se salta el rol con su propio hintStyle', () {
    // El rol sólo sirve si nadie lo pisa. Cuando una pantalla escribía su
    // `hintStyle: theme.type.body.copyWith(...)`, se llevaba por delante la
    // cursiva y volvía a dejar el ejemplo con pinta de dato.
    final offenders = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      if (file.path.contains('core/theme/themes/')) continue;
      if (file.readAsStringSync().contains('hintStyle:')) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Estas pantallas pisan el estilo del ejemplo:\n  '
          '${offenders.join('\n  ')}\n'
          'Quita el `hintStyle:` y deja que lo ponga el tema.',
    );
  });
}
