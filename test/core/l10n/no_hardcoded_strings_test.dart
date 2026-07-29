import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fija dos invariantes que ya se rompieron una vez y no se notan al probar la
/// app en español.
///
/// **Por qué existe este archivo.** Los dos defectos que cubre eran invisibles
/// desde el dispositivo de desarrollo: la app se veía perfecta en español, y las
/// cuatro tarjetas de la hoja de registro se abrían… si probabas la primera. Los
/// tests de widget no los habrían encontrado —no hay nada que falle—, así que se
/// comprueban leyendo el propio código.
void main() {
  group('todo texto visible pasa por l10n ·', () {
    // Cadenas de una pantalla que el usuario lee. Se buscan en los sitios donde
    // acaban de verdad: un `Text('…')`, el rótulo de un campo, un hint.
    final visibleString = RegExp(
      r"""(?:Text\(\s*|hintText:\s*|labelText:\s*|helperText:\s*|title:\s*|label:\s*|subtitle:\s*)'([^']{3,})'""",
    );

    /// Una cadena "sospechosa" es la que un hispanohablante escribiría sin
    /// pensar. Se detecta por tildes/eñe o por palabras funcionales del español,
    /// no por «tiene letras»: así no salta con `'mmHg'`, `'LDL'` o `'MY VITALS'`,
    /// que son iguales en todos los idiomas.
    bool looksSpanish(String s) {
      if (RegExp(r'[áéíóúñÁÉÍÓÚÑ¿¡]').hasMatch(s)) return true;
      const words = [
        ' de ', ' la ', ' el ', ' los ', ' las ', ' un ', ' una ', ' que ',
        ' para ', ' con ', ' tu ', ' tus ', ' se ', ' del ', ' por ', ' en ',
        ' y ', ' o ', ' no ', ' si ', ' al ',
      ];
      final padded = ' ${s.toLowerCase()} ';
      return words.any(padded.contains);
    }

    test('ninguna pantalla escribe texto en español a mano', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Lo generado y el catálogo de temas quedan fuera: el primero ES la
        // traducción, y los nombres de tema («Pulso Clínico») son marca, no
        // interfaz traducible.
        if (entity.path.contains('/generated/')) continue;
        if (entity.path.endsWith('theme_catalog.dart')) continue;
        // El muestrario del selector rotula estados de ejemplo, no datos del
        // usuario: es una lámina de diseño dentro de la propia pantalla.
        if (entity.path.endsWith('theme_preview_card.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          for (final m in visibleString.allMatches(line)) {
            final text = m.group(1)!;
            if (text.startsWith(r'$') || text.startsWith('package:')) continue;
            if (!looksSpanish(text)) continue;
            offenders.add('${entity.path}:${i + 1}  «$text»');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Estas cadenas se verían en español en un móvil configurado en '
            'inglés, mientras el resto de la pantalla está traducido:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('la hoja «Registrar indicadores» ·', () {
    test('las cuatro tarjetas llevan a su pantalla', () {
      final src = File('lib/core/widgets/register_modal.dart').readAsStringSync();

      // Durante un tiempo solo navegaba «Antropometría»; las otras tres cerraban
      // la hoja y no iban a ninguna parte. Las cuatro rutas existían y las
      // cuatro pantallas se abrían desde el panel, así que era un cable sin
      // conectar y no se notaba salvo tocando justo esa tarjeta.
      for (final route in const [
        '/record-anthropometric',
        '/record-vital-signs',
        '/record-lipid',
        '/record-body-composition',
      ]) {
        expect(
          src.contains("context.push('$route')"),
          isTrue,
          reason: 'La hoja de registro no navega a $route',
        );
      }
    });
  });
}
