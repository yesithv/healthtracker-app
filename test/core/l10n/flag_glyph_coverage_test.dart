// LA FUENTE DE BANDERAS Y EL CATÁLOGO DE PAÍSES NO PUEDEN SEPARARSE.
//
// Las banderas del selector de prefijo telefónico y del de idioma no son
// imágenes: son emoji, y se derivan del código ISO del país
// (`'CO'` → `🇨🇴`, dos «regional indicator symbols»). Eso funcionaba mientras la
// app usaba las fuentes del sistema. Al empaquetar las suyas se perdió ese
// respaldo, y como ninguna de las cuatro familias de texto trae emoji, las
// banderas se pintaban como cuadritos vacíos.
//
// El arreglo es empaquetar Noto Color Emoji, pero RECORTADA: la fuente entera
// pesa 10,8 MB y la app sólo enseña 47 banderas, así que se lleva un recorte de
// 159 KB con exactamente esas.
//
// Ese ahorro crea una atadura: si mañana alguien añade un país a
// `countries.dart` y no rehace el recorte, esa bandera —y sólo esa— vuelve a
// salir como un cuadrito, en una pantalla que casi nadie abre al probar. Esta
// prueba es la que lo impide: lee el catálogo, lee la fuente, y exige que
// coincidan en los dos sentidos.
//
// Para rehacer el recorte: `python3 tool/subset_flag_font.py`, que lee el
// catálogo del propio código. Hacen falta `fontTools` y la fuente completa (en
// Debian, el paquete `fonts-noto-color-emoji`).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';

const _font = 'assets/fonts/NotoColorEmoji-Flags.ttf';

/// Primer «regional indicator symbol»: `A`.
const _riA = 0x1F1E6;

void main() {
  group('Banderas', () {
    late final Set<String> inFont;

    setUpAll(() {
      inFont = _flagsIn(File(_font));
    });

    test('el recorte trae banderas de verdad', () {
      expect(
        inFont,
        isNotEmpty,
        reason:
            '$_font no declara ninguna bandera. O el recorte salió mal o el '
            'lector de este fichero no supo leerlo; en ambos casos el resto de '
            'esta prueba mediría humo.',
      );
    });

    test('todo país del catálogo tiene su bandera', () {
      final missing = Countries.all
          .map((c) => c.iso)
          .where((iso) => !inFont.contains(iso))
          .toList();

      expect(
        missing,
        isEmpty,
        reason:
            'Estos países saldrían con un cuadrito vacío en vez de bandera: '
            '${missing.join(', ')}.\n'
            'Hay que rehacer el recorte de $_font incluyéndolos.',
      );
    });

    test('el recorte no carga con banderas que nadie enseña', () {
      // El otro sentido. No es un fallo de cara al usuario, pero sí peso
      // muerto en el binario, y sobre todo señal de que el recorte y el
      // catálogo dejaron de ir a la par.
      final catalogue = Countries.all.map((c) => c.iso).toSet();
      final extra = inFont.difference(catalogue).toList()..sort();

      expect(
        extra,
        isEmpty,
        reason:
            'El recorte lleva ${extra.length} bandera(s) que el catálogo ya no '
            'lista: ${extra.join(', ')}.\n'
            'Si el país se quitó a propósito, rehaz el recorte sin él.',
      );
    });

    test('el ISO de un país produce la bandera que le toca', () {
      // La derivación vive en `Country.flag`. Si alguien la toca, las banderas
      // podrían salir todas correctas menos las de los ISO con letras del final
      // del alfabeto, que es el tipo de fallo que no se ve mirando por encima.
      expect(const Country('CO', 'Colombia', '+57').flag, '\u{1F1E8}\u{1F1F4}');
      expect(
        const Country('ZA', 'Sudáfrica', '+27').flag,
        '\u{1F1FF}\u{1F1E6}',
      );
      expect(
        const Country('AE', 'Emiratos', '+971').flag,
        '\u{1F1E6}\u{1F1EA}',
      );
    });
  });
}

// ── Lectura de las banderas que declara la fuente ────────────────────────────
//
// Una bandera no es un carácter: es una LIGADURA de dos «regional indicator
// symbols» declarada en la tabla `GSUB`. Que la fuente tenga en su `cmap` las
// 24 letras sueltas no dice nada sobre qué banderas sabe pintar; hay que mirar
// qué pares están ligados. Se leen las tablas a mano —sólo lo justo— porque
// Dart no trae con qué.

Set<String> _flagsIn(File file) {
  final data = ByteData.sublistView(file.readAsBytesSync());

  int? tableAt(String wanted) {
    final numTables = data.getUint16(4);
    for (var i = 0; i < numTables; i++) {
      final rec = 12 + i * 16;
      final tag = String.fromCharCodes(
        Uint8List.sublistView(data, rec, rec + 4),
      );
      if (tag == wanted) return data.getUint32(rec + 8);
    }
    return null;
  }

  // 1 · Del `cmap`, qué glifo dibuja cada indicador regional.
  final riGlyph = <int, int>{}; // punto de código → id de glifo
  final cmap = tableAt('cmap');
  if (cmap == null) return {};
  final subtables = data.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final off = cmap + data.getUint32(cmap + 4 + i * 8 + 4);
    if (off + 2 > data.lengthInBytes) continue;
    // Los indicadores regionales viven fuera del BMP: formato 12.
    if (data.getUint16(off) != 12) continue;
    final groups = data.getUint32(off + 12);
    for (var g = 0; g < groups; g++) {
      final rec = off + 16 + g * 12;
      final first = data.getUint32(rec);
      final last = data.getUint32(rec + 4);
      final startGlyph = data.getUint32(rec + 8);
      for (var c = first; c <= last; c++) {
        if (c >= _riA && c < _riA + 26) riGlyph[c] = startGlyph + (c - first);
      }
    }
  }
  if (riGlyph.isEmpty) return {};

  final letterOf = {
    for (final e in riGlyph.entries)
      e.value: String.fromCharCode('A'.codeUnitAt(0) + e.key - _riA),
  };

  // 2 · Del `GSUB`, qué pares están ligados.
  final gsub = tableAt('GSUB');
  if (gsub == null) return {};
  final lookupList = gsub + data.getUint16(gsub + 8);
  final lookupCount = data.getUint16(lookupList);

  final flags = <String>{};
  for (var l = 0; l < lookupCount; l++) {
    final lookup = lookupList + data.getUint16(lookupList + 2 + l * 2);
    if (data.getUint16(lookup) != 4) continue; // 4 = sustitución por ligadura
    final subCount = data.getUint16(lookup + 4);
    for (var s = 0; s < subCount; s++) {
      final sub = lookup + data.getUint16(lookup + 6 + s * 2);
      final coverage = sub + data.getUint16(sub + 2);
      final setCount = data.getUint16(sub + 4);
      final first = _coverageGlyphs(data, coverage);
      if (first.length != setCount) continue;

      for (var i = 0; i < setCount; i++) {
        final firstLetter = letterOf[first[i]];
        if (firstLetter == null) continue;
        final set = sub + data.getUint16(sub + 6 + i * 2);
        final ligCount = data.getUint16(set);
        for (var g = 0; g < ligCount; g++) {
          final lig = set + data.getUint16(set + 2 + g * 2);
          final compCount = data.getUint16(lig + 2);
          if (compCount != 2) continue; // una bandera son dos letras
          final second = letterOf[data.getUint16(lig + 4)];
          if (second != null) flags.add('$firstLetter$second');
        }
      }
    }
  }
  return flags;
}

/// Los glifos que cubre una tabla `Coverage`, en su orden.
List<int> _coverageGlyphs(ByteData data, int p) {
  final out = <int>[];
  switch (data.getUint16(p)) {
    case 1:
      final count = data.getUint16(p + 2);
      for (var i = 0; i < count; i++) {
        out.add(data.getUint16(p + 4 + i * 2));
      }
    case 2:
      final ranges = data.getUint16(p + 2);
      for (var r = 0; r < ranges; r++) {
        final rec = p + 4 + r * 6;
        final start = data.getUint16(rec);
        final end = data.getUint16(rec + 2);
        for (var g = start; g <= end; g++) {
          out.add(g);
        }
      }
  }
  return out;
}
