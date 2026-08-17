import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';

/// El muestreo y el formato del eje son la última milla antes de `fl_chart`: si
/// se ahogan con un caso degenerado, la gráfica se cae con datos que la app
/// permite guardar. Estas pruebas los someten a los extremos que la serie curada
/// de la demo nunca produce —una serie de un punto, todas las fechas iguales,
/// primer y último coincidentes— para blindar el dibujo antes de que un usuario
/// real los provoque.
void main() {
  group('downsample con entradas degeneradas ·', () {
    test('lista vacía no lanza y devuelve vacía', () {
      expect(downsample<int>(const [], maxPoints: 24), isEmpty);
    });

    test('un solo punto se devuelve tal cual', () {
      expect(downsample(const [42], maxPoints: 24), equals(const [42]));
    });

    test('dos puntos con el tope mínimo se conservan enteros', () {
      expect(downsample(const [7, 9], maxPoints: 2), equals(const [7, 9]));
    });

    test('valores repetidos (línea plana) conservan primer y último', () {
      // Una serie donde todo vale lo mismo: la gráfica sale plana, pero el
      // muestreo no puede perder los extremos ni descolocar el conteo.
      final flat = List.filled(500, 3);
      final out = downsample(flat, maxPoints: 24);
      expect(out, hasLength(24));
      expect(out.first, 3);
      expect(out.last, 3);
    });
  });

  group('axisLabelStep en los bordes ·', () {
    test('un solo punto pide paso 1', () {
      expect(axisLabelStep(1, maxLabels: 6), equals(1));
    });

    test('cero puntos no revienta y da paso 1', () {
      expect(axisLabelStep(0, maxLabels: 6), equals(1));
    });
  });

  group('axisDateFormat cuando el rango se colapsa ·', () {
    test('primer y último en el MISMO instante (span 0) → día y mes', () {
      final d = DateTime(2026, 5, 10, 9, 30);
      final f = axisDateFormat(d, d);
      expect(f.pattern, contains('d'));
      expect(f.pattern, isNot(contains('y')));
    });

    test('fechas invertidas: usa el valor absoluto del abanico', () {
      // last ANTES que first: el span se toma en valor absoluto, así que dos
      // años al revés siguen pidiendo mes y año, no un formato roto.
      final f = axisDateFormat(DateTime(2026, 1, 1), DateTime(2024, 1, 1));
      expect(f.pattern, contains('yy'));
    });
  });
}
