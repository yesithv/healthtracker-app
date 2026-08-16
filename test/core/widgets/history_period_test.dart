// EL FILTRO DE PERIODO RECORTA POR LA VENTANA QUE DICE, Y «SIEMPRE» NO RECORTA.
//
// Cada historial repetía a mano el mismo `if (_selectedFilter == '7days') …`
// sobre cadenas sueltas. Al unificarlo en `HistoryPeriod`, la ventana de días y
// el filtrado viven en un solo sitio; esta prueba fija ese contrato para que los
// cuatro módulos —y los que vengan— recorten igual.

import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/widgets/period_filter_dropdown.dart';

void main() {
  test('la ventana en días de cada tramo', () {
    expect(HistoryPeriod.last7Days.days, 7);
    expect(HistoryPeriod.last30Days.days, 30);
    expect(HistoryPeriod.last6Months.days, 180);
    expect(HistoryPeriod.allTime.days, isNull);
  });

  test('filtra por la ventana y conserva el resto', () {
    final now = DateTime.now();
    final dates = [
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 20)),
      now.subtract(const Duration(days: 200)),
    ];

    List<DateTime> within(HistoryPeriod p) =>
        p.filter<DateTime>(dates, (d) => d).toList();

    expect(within(HistoryPeriod.last7Days), hasLength(1));
    expect(within(HistoryPeriod.last30Days), hasLength(2));
    expect(within(HistoryPeriod.last6Months), hasLength(2));
    expect(within(HistoryPeriod.allTime), hasLength(3));
  });
}
