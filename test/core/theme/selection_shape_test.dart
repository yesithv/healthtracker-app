// EL REALCE DE LO ELEGIDO ES UN RECTÁNGULO REDONDEADO, NUNCA UNA CÁPSULA.
//
// El fondo que marca la pestaña activa del menú principal tomaba su forma de
// `radiusControl`, el radio del botón. Un tema es libre de hacer sus botones en
// cápsula —«Pulso Clínico» los pone en 30—, así que sobre un indicador alto ese
// 30 redondeaba las esquinas hasta leerse como círculo en un tema y como
// rectángulo en otro: la misma pantalla se veía distinta según el tema.
//
// Ahora la forma del realce la pone su propio token, `surfaces.radiusSelection`,
// separado a propósito del radio del botón. Esta prueba impide que un tema nuevo
// vuelva a dejar el realce circular: cada tema tiene que declarar
// `radiusSelection` dentro del rango que garantiza rectángulo redondeado.
//
// Es el mismo criterio que `icon_enclosure_shape_test.dart` aplica a la caja del
// icono. Si al añadir un tema salta esta prueba, la pregunta no es «¿cómo la
// callo?» sino «¿de verdad quiero que el realce de lo elegido sea una cápsula?».
// La respuesta que el diseño ya tomó es que no.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('El realce de lo elegido', () {
    test('cada tema lo declara como rectángulo redondeado, no cápsula', () {
      // Un tema es un fichero que construye sus propias superficies; el resto de
      // `themes/` son ayudantes (la escala tipográfica, por ejemplo).
      final themes = Directory('lib/core/theme/themes')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('AppSurfaces('))
          .map((f) => f.path)
          .toList();
      expect(themes, hasLength(greaterThanOrEqualTo(2)));

      for (final path in themes) {
        final src = File(path).readAsStringSync();
        final match = RegExp(r'radiusSelection:\s*([\d.]+)').firstMatch(src);
        expect(match, isNotNull, reason: '$path no declara `radiusSelection`.');
        final radius = double.parse(match!.group(1)!);
        expect(
          radius,
          inInclusiveRange(4, 18),
          reason:
              '$path pone `radiusSelection: $radius`. Por debajo de 4 el realce '
              'es un rectángulo seco y por encima de 18 vuelve a leerse como '
              'cápsula sobre la pestaña activa de la barra; en ambos casos deja '
              'de ser el rectángulo redondeado que el diseño exige en todo tema.',
        );
      }
    });
  });
}
