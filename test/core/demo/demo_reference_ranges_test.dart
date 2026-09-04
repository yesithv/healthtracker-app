import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myvitals_healthtracker_app/core/demo/demo_reference_ranges.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_seeder.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';

/// Los rangos congelados de la demo, contra la respuesta real de la API.
///
/// **Por qué existe.** Los umbrales clínicos viven en la base y los administra el
/// backoffice; la demo, que corre sin servidor, necesita una copia. Una copia es
/// exactamente lo que se separa del original sin que nadie se entere — ya pasó con
/// las migraciones del BackOffice-Api, y por eso hay un `check-migration-parity.sh`.
///
/// Aquí el original es `test/fixtures/demo_reference_ranges.json`: la respuesta
/// literal de `GET /api/v1/me/reference-ranges` para esta persona, regenerable con
/// `healthtracker-localdev/scripts/check-demo-ranges.sh`.
void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/demo_reference_ranges.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('los rangos congelados de la demo ·', () {
    test('son exactamente los que devuelve la API para esa persona', () {
      // Compara el JSON entero, no solo unos cuantos números: lo que se busca es
      // que nadie edite el .dart a mano y se olvide del fixture, o al revés.
      expect(
        jsonDecode(jsonEncode(kDemoReferenceRangeIndicators)),
        equals(fixture['indicators']),
        reason:
            'demo_reference_ranges.dart y el fixture divergieron. Regenera con '
            'healthtracker-localdev/scripts/check-demo-ranges.sh',
      );
    });

    test('la persona de la demo sigue dentro del tramo de edad congelado', () {
      // LA trampa: nació en 1990, así que en 2030 cruza a la banda 40-59 y estas
      // cifras dejarían de ser las suyas en silencio. Que falle el día que pase.
      final now = DateTime.now();
      var age = now.year - kDemoBirthDate.year;
      final tuvoCumple =
          now.month > kDemoBirthDate.month ||
          (now.month == kDemoBirthDate.month && now.day >= kDemoBirthDate.day);
      if (!tuvoCumple) age -= 1;

      expect(
        age,
        inInclusiveRange(kDemoAgeBandMin, kDemoAgeBandMax),
        reason:
            'La persona de la demo tiene $age años y las cifras congeladas son '
            'del tramo $kDemoAgeBandMin-$kDemoAgeBandMax. Hay que regenerar el '
            'fixture con su tramo nuevo, o mover su fecha de nacimiento.',
      );
    });

    test('la fecha de nacimiento es la misma que siembra el seeder', () {
      // Dos sitios la escriben; si se separan, los rangos serían de otra persona.
      final sembrada =
          DemoSeeder.demoPreferences()['user_birth_date'] as String;
      expect(DateTime.parse(sembrada), equals(kDemoBirthDate));
    });
  });

  group('lo que la demo enseña con esos rangos ·', () {
    setUp(() {
      ReferenceRangesStore.instance.setForTesting(const {});
    });

    test('un 26 % de grasa es NORMAL para esta mujer, no «elevada»', () {
      // El caso concreto que rompía el relato: la serie de la demo baja de 36 %
      // a 26 %, y el respaldo genérico —ciego a sexo, edad y báscula— pintaba ese
      // final en ámbar. Su banda normal llega hasta 32.9.
      ReferenceRangesStore.instance.seedDemo();

      final band = ReferenceRangesStore.instance.classify('BODY_FAT', 26.0);

      expect(band, isNotNull);
      expect(band!.bandCode, 'NORMAL');
    });

    test('y un 36 % sigue siendo alto: la demo empieza donde debe', () {
      ReferenceRangesStore.instance.seedDemo();

      expect(
        ReferenceRangesStore.instance.classify('BODY_FAT', 36.0)!.bandCode,
        'HIGH',
      );
    });

    test('las gráficas tienen franjas: los cuatro indicadores traen bandas', () {
      // Sin bandas, `bandRangeAnnotations` no pinta ninguna zona —y hace bien, no
      // se inventa interpretación—, así que la demo se veía en blanco y negro.
      ReferenceRangesStore.instance.seedDemo();

      for (final code in const [
        'BMI',
        'BODY_FAT',
        'VISCERAL_FAT_LEVEL',
        'MUSCLE_PCT',
      ]) {
        expect(
          ReferenceRangesStore.instance.bandsOf(code),
          isNotEmpty,
          reason: '$code se quedó sin bandas en la demo',
        );
      }
    });
  });
}
