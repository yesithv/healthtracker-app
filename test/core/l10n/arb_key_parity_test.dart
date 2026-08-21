// LOS CINCO IDIOMAS TIENEN QUE DECLARAR LAS MISMAS CLAVES.
//
// `gen-l10n` no falla cuando a un idioma le falta una clave: la RELLENA con el
// texto de la plantilla (inglés) y sigue. El resultado es una app que se ve
// entera en español —donde se desarrolla— y que a un usuario en alemán le pinta
// media pantalla en inglés sin que nada avise. Así se coló todo el bloque del
// índice cintura-cadera/cintura-altura: 15 claves que existían en `en`/`es` y
// faltaban en `de`, `it` y `pt`, que las mostraban como «Waist-to-hip»,
// «NORMAL», «your waist»… en una pantalla por lo demás traducida.
//
// El defecto era invisible desde el dispositivo de desarrollo y ningún test de
// widget lo habría encontrado —no hay nada que reviente—, así que se comprueba
// leyendo los propios `.arb`: toma `app_en.arb` como plantilla y exige que cada
// idioma declare EXACTAMENTE su mismo conjunto de claves de mensaje.
//
// Segunda invariante: los PLACEHOLDERS de una cadena tienen que sobrevivir a la
// traducción. Si `en` dice `Log {measure}…` y una traducción se come el
// `{measure}`, `gen-l10n` no interpola nada y el hueco sale vacío en pantalla.
// Se comparan sólo los placeholders simples `{nombre}`; los mensajes ICU
// (`plural`/`select`) se saltan porque sus ramas (`one{tablet} other{tablets}`)
// cambian de texto por idioma a propósito y su argumento ya lo valida la
// plantilla vía `@`-metadata.
//
// Complementa a `arb_glyph_coverage_test.dart` (que el texto de los `.arb` se
// pueda dibujar) y a `no_hardcoded_strings_test.dart` (que el texto visible
// pase por los `.arb`). Éste garantiza que ese texto exista en todos los idiomas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directorio de los `.arb` (relativo a la raíz del proyecto, donde corre el test).
const _arbDir = 'lib/l10n';

/// Plantilla: la fuente de verdad de qué claves existen (ver `l10n.yaml`).
const _templateLocale = 'en';

/// Los demás idiomas se miden contra la plantilla.
const _otherLocales = ['es', 'de', 'it', 'pt'];

/// Claves de mensaje de un `.arb`: las que NO empiezan por `@` (metadatos de
/// `gen-l10n`) ni por `@@` (como `@@locale`).
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Map<String, dynamic> _loadArb(String locale) {
  final file = File('$_arbDir/app_$locale.arb');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'No se encontró ${file.path}. ¿Se renombró un idioma?',
  );
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Placeholders simples `{nombre}` de una cadena. Deja fuera los mensajes ICU
/// (`plural`/`select`), cuyas ramas contienen texto entre llaves que cambia por
/// idioma y no son placeholders.
Set<String> _simplePlaceholders(String value) {
  if (value.contains(', plural,') || value.contains(', select,')) {
    return const {};
  }
  return RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m.group(1)!).toSet();
}

void main() {
  group('Paridad de claves entre idiomas ·', () {
    late final Map<String, dynamic> template;
    late final Set<String> templateKeys;

    setUpAll(() {
      template = _loadArb(_templateLocale);
      templateKeys = _messageKeys(template);
    });

    test('la plantilla declara claves', () {
      expect(
        templateKeys,
        isNotEmpty,
        reason: 'app_$_templateLocale.arb no tiene claves de mensaje.',
      );
    });

    for (final locale in _otherLocales) {
      test('app_$locale.arb declara exactamente las claves de la plantilla', () {
        final keys = _messageKeys(_loadArb(locale));

        final missing = templateKeys.difference(keys).toList()..sort();
        final extra = keys.difference(templateKeys).toList()..sort();

        expect(
          missing,
          isEmpty,
          reason:
              'A "$locale" le faltan ${missing.length} clave(s) que sí están '
              'en la plantilla; gen-l10n las rellenaría con el texto en inglés: '
              '$missing',
        );
        expect(
          extra,
          isEmpty,
          reason:
              '"$locale" declara ${extra.length} clave(s) que la plantilla no '
              'tiene; son código muerto (sin getter) o falta añadirlas a '
              'app_$_templateLocale.arb: $extra',
        );
      });
    }

    for (final locale in _otherLocales) {
      test('app_$locale.arb conserva los placeholders de cada cadena', () {
        final arb = _loadArb(locale);
        final offenders = <String>[];

        for (final key in templateKeys) {
          if (!arb.containsKey(key)) continue; // ya lo cubre el test anterior
          final expected = _simplePlaceholders(template[key] as String);
          final actual = _simplePlaceholders(arb[key] as String);
          final same =
              expected.length == actual.length && expected.containsAll(actual);
          if (!same) {
            offenders.add('$key: esperados $expected, encontrados $actual');
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'En "$locale" hay cadenas cuyos placeholders no coinciden con la '
              'plantilla; el hueco saldría vacío en pantalla:\n'
              '${offenders.join('\n')}',
        );
      });
    }
  });
}
