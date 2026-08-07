import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';

/// El bug que estas piezas arreglan era invisible en español y en la demo: las
/// gráficas recortaban a los últimos 6 puntos e ignoraban el filtro de tiempo, así
/// que «Siempre» enseñaba una línea plana reciente en vez de la mejora de dos años.
/// El muestreo y el formato del eje son Dart puro, así que se comprueban aquí sin
/// levantar un solo widget.
void main() {
  group('downsample ·', () {
    test('deja la lista igual si ya cabe en el tope', () {
      final items = List.generate(6, (i) => i);
      expect(downsample(items, maxPoints: 24), equals(items));
    });

    test('reduce al tope exacto cuando hay de sobra', () {
      final items = List.generate(1000, (i) => i);
      final out = downsample(items, maxPoints: 24);
      expect(out, hasLength(24));
    });

    test('conserva SIEMPRE el primer y el último punto', () {
      final items = List.generate(731, (i) => i); // dos años de días
      final out = downsample(items, maxPoints: 24);
      expect(out.first, equals(0), reason: 'el arranque cuenta la mejora');
      expect(out.last, equals(730), reason: 'el valor más reciente cuenta');
    });

    test('muestrea de forma monótona (sin desordenar ni repetir saltos raros)', () {
      final items = List.generate(500, (i) => i);
      final out = downsample(items, maxPoints: 10);
      for (var i = 1; i < out.length; i++) {
        expect(out[i], greaterThan(out[i - 1]));
      }
    });

    test('no falla con listas al límite del tope', () {
      final items = List.generate(24, (i) => i);
      expect(downsample(items, maxPoints: 24), equals(items));
      expect(downsample(List.generate(25, (i) => i), maxPoints: 24), hasLength(24));
    });
  });

  group('axisLabelStep ·', () {
    test('paso 1 cuando caben todas las etiquetas', () {
      expect(axisLabelStep(6, maxLabels: 6), equals(1));
      expect(axisLabelStep(3, maxLabels: 6), equals(1));
    });

    test('agrupa para no pasar del tope de etiquetas', () {
      expect(axisLabelStep(24, maxLabels: 6), equals(4));
      expect(axisLabelStep(30, maxLabels: 6), equals(5));
    });
  });

  group('axisDateFormat ·', () {
    test('día y mes en rangos cortos', () {
      final f = axisDateFormat(DateTime(2026, 1, 1), DateTime(2026, 1, 20));
      expect(f.pattern, contains('d'));
      expect(f.pattern, isNot(contains('y')));
    });

    test('solo mes en rangos de meses', () {
      final f = axisDateFormat(DateTime(2026, 1, 1), DateTime(2026, 6, 1));
      expect(f.pattern, equals('MMM'));
    });

    test('mes y año cuando el rango cruza más de un año', () {
      final f = axisDateFormat(DateTime(2024, 1, 1), DateTime(2026, 1, 1));
      expect(f.pattern, contains('yy'));
    });
  });
}
