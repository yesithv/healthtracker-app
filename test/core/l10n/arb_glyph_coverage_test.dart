// Toda cadena visible tiene que poder DIBUJARSE.
//
// La app dejó de usar `google_fonts` (descarga en tiempo de ejecución) y ahora
// empaqueta seis TTF en `assets/fonts`. Eso quitó la latencia del primer pinta-
// do, pero también quitó la red de seguridad: si una traducción usa un carácter
// que ninguna fuente empaquetada tiene, Flutter no puede caer a otra fuente y
// pinta el «tofu», el cuadrito vacío. No hay error, no hay aviso: sale en
// pantalla y ya.
//
// Así se coló un `✦` en `saveAndEarnXp` y una `→` en dos respuestas del FAQ.
//
// Esta prueba abre los TTF, lee sus tablas `cmap` y calcula la INTERSECCIÓN de
// los puntos de código que cubren las familias de TEXTO; después recorre los
// cinco `.arb` y exige que cada carácter esté en esa intersección. La
// intersección —y no la unión— porque una cadena cualquiera puede acabar
// pintándose con cualquiera de las familias según el tema activo.
//
// El recorte de Noto Color Emoji queda FUERA de esa cuenta, y no por comodidad:
// no es una familia de texto sino el RESPALDO al que Flutter cae cuando la
// familia activa no sabe pintar algo (ver `TypeScale.fallback`). Amplía la
// cobertura, no la limita. Meterlo en la intersección la dejaría en las 24
// letras que trae y haría fallar la prueba entera; unirlo después es lo que
// describe de verdad lo que la app puede dibujar. Qué banderas trae ese recorte
// lo comprueba `flag_glyph_coverage_test.dart`, que es otra pregunta.
//
// Se apoya en `no_hardcoded_strings_test.dart`: aquélla garantiza que el texto
// visible vive en los `.arb`, y ésta que el texto de los `.arb` se puede pintar.
//
// Si esta prueba falla al añadir un símbolo nuevo, hay dos salidas honestas:
// usar un carácter que sí esté cubierto, o sacar el símbolo de la cadena y
// dibujarlo como `Icon` (los iconos de Material no dependen de estas fuentes).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cobertura de glifos en las traducciones', () {
    late final Map<String, Set<int>> coveragePerFont;
    late final Set<int> shared;

    setUpAll(() {
      final fonts =
          Directory('assets/fonts')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.ttf'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(
        fonts,
        isNotEmpty,
        reason: 'No se encontró ningún .ttf en assets/fonts.',
      );

      final all = {for (final f in fonts) _basename(f.path): _codePointsOf(f)};

      // Las familias de texto son las que TIENEN que cubrirlo todo; el respaldo
      // sólo suma.
      coveragePerFont = {
        for (final e in all.entries)
          if (!_isFallback(e.key)) e.key: e.value,
      };
      final fallback = {
        for (final e in all.entries)
          if (_isFallback(e.key)) ...e.value,
      };

      expect(
        coveragePerFont,
        isNotEmpty,
        reason: 'Todas las fuentes quedaron clasificadas como respaldo.',
      );

      shared = coveragePerFont.values
          .reduce((a, b) => a.intersection(b))
          .union(fallback);
    });

    test('cada TTF empaquetado expone una cmap legible', () {
      coveragePerFont.forEach((name, points) {
        expect(
          points.length,
          greaterThan(100),
          reason:
              '$name declaró solo ${points.length} puntos de código. '
              'O la fuente está truncada o el lector de cmap no supo leerla; '
              'en ambos casos el resto de esta prueba mediría humo.',
        );
      });
    });

    test('todo carácter de los .arb se puede dibujar en cualquier tema', () {
      final arbs =
          Directory('lib/l10n')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.arb'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(arbs, isNotEmpty, reason: 'No se encontró ningún .arb.');

      // origen[punto de código] = claves donde aparece, para que el fallo diga
      // exactamente qué traducción hay que tocar.
      final origin = <int, Set<String>>{};

      for (final arb in arbs) {
        final locale = _basename(arb.path);
        final decoded =
            jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          // Las claves `@algo` son metadatos del propio ARB (descripciones para
          // quien traduce), no llegan a pantalla.
          if (key.startsWith('@')) return;
          if (value is! String) return;
          for (final rune in value.runes) {
            if (_isIgnorable(rune)) continue;
            origin.putIfAbsent(rune, () => <String>{}).add('$locale:$key');
          }
        });
      }

      final missing = origin.keys.where((r) => !shared.contains(r)).toList()
        ..sort();

      expect(
        missing,
        isEmpty,
        reason: missing.isEmpty
            ? ''
            : missing.map((r) {
                final absent = coveragePerFont.entries
                    .where((e) => !e.value.contains(r))
                    .map((e) => e.key)
                    .join(', ');
                final where = origin[r]!.toList()..sort();
                final sample = where.take(4).join(', ');
                final rest = where.length > 4 ? ' (+${where.length - 4})' : '';
                return '\n  ${_fmt(r)} se pintaría como un cuadrito vacío.'
                    '\n     falta en: $absent'
                    '\n     usado en: $sample$rest';
              }).join(),
      );
    });
  });
}

/// Fuentes que NO son familias de texto sino respaldo para lo que aquéllas no
/// saben pintar. Declaradas en `TypeScale.fallback`.
bool _isFallback(String name) => name.contains('NotoColorEmoji');

bool _isIgnorable(int rune) =>
    rune == 0x0A || rune == 0x0D || rune == 0x09 || rune == 0x20;

String _basename(String path) => path.split(Platform.pathSeparator).last;

String _fmt(int rune) =>
    'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')} '
    "'${String.fromCharCode(rune)}'";

// ── Lector mínimo de `cmap` ──────────────────────────────────────────────────
//
// Solo lo justo para responder «¿tiene esta fuente un glifo para este punto de
// código?». Recorre todas las subtablas de formato 4 (BMP) y 12 (fuera del BMP)
// y une lo que declaran. Un punto que mapea al glifo 0 —el `.notdef`, que es
// literalmente el cuadrito— no cuenta como cubierto.

Set<int> _codePointsOf(File file) {
  final data = ByteData.sublistView(file.readAsBytesSync());
  final numTables = data.getUint16(4);

  var cmapOffset = -1;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(Uint8List.sublistView(data, rec, rec + 4));
    if (tag == 'cmap') {
      cmapOffset = data.getUint32(rec + 8);
      break;
    }
  }
  if (cmapOffset < 0) return <int>{};

  final out = <int>{};
  final numSubtables = data.getUint16(cmapOffset + 2);
  for (var i = 0; i < numSubtables; i++) {
    final rec = cmapOffset + 4 + i * 8;
    final subtable = cmapOffset + data.getUint32(rec + 4);
    if (subtable + 2 > data.lengthInBytes) continue;
    switch (data.getUint16(subtable)) {
      case 4:
        _readFormat4(data, subtable, out);
      case 12:
        _readFormat12(data, subtable, out);
    }
  }
  return out;
}

void _readFormat4(ByteData data, int p, Set<int> out) {
  final length = data.getUint16(p + 2);
  final end = p + length;
  final segCountX2 = data.getUint16(p + 6);
  final endCodes = p + 14;
  final startCodes = endCodes + segCountX2 + 2; // +2 por el `reservedPad`
  final idDeltas = startCodes + segCountX2;
  final idRangeOffsets = idDeltas + segCountX2;

  for (var s = 0; s < segCountX2; s += 2) {
    final last = data.getUint16(endCodes + s);
    final first = data.getUint16(startCodes + s);
    if (first == 0xFFFF) continue; // segmento centinela
    final delta = data.getInt16(idDeltas + s);
    final rangeOffsetPos = idRangeOffsets + s;
    final rangeOffset = data.getUint16(rangeOffsetPos);

    for (var c = first; c <= last; c++) {
      int glyph;
      if (rangeOffset == 0) {
        glyph = (c + delta) & 0xFFFF;
      } else {
        final at = rangeOffsetPos + rangeOffset + (c - first) * 2;
        if (at + 2 > end || at + 2 > data.lengthInBytes) continue;
        glyph = data.getUint16(at);
        if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
      }
      if (glyph != 0) out.add(c);
    }
  }
}

void _readFormat12(ByteData data, int p, Set<int> out) {
  final groups = data.getUint32(p + 12);
  for (var g = 0; g < groups; g++) {
    final rec = p + 16 + g * 12;
    if (rec + 12 > data.lengthInBytes) return;
    final first = data.getUint32(rec);
    final last = data.getUint32(rec + 4);
    final startGlyph = data.getUint32(rec + 8);
    if (startGlyph == 0) continue;
    for (var c = first; c <= last; c++) {
      out.add(c);
    }
  }
}
