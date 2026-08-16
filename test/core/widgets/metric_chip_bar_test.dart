// LOS CHIPS DE SELECCIÓN SON CÓMODOS DE TOCAR Y DE LEER.
//
// El selector de métrica del historial de antropometría se dibujaba a ojo dentro
// de la propia pantalla: alto 34, texto 12 y muy pegados entre sí. Para alguien
// con dificultad visual o motriz eso es un blanco diminuto. Al extraerlo a
// `MetricChipBar`, las medidas dejaron de ser un número suelto en una pantalla y
// pasaron a ser una invariante: la fila da una zona táctil holgada (≥ 44 lógicos,
// el mínimo recomendado) y separa los chips lo suficiente para no leerse como un
// bloque. Esta prueba impide que se vuelvan a encoger.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_chip_bar.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';

enum _Demo { a, b, c }

const _family = Tone(
  accent: Color(0xFFB45309),
  surface: Color(0xFFFDF3E7),
  onAccent: Color(0xFFFFFFFF),
);

Widget _host({
  required _Demo selected,
  required ValueChanged<_Demo> onSelected,
}) {
  return MaterialApp(
    theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
    home: Scaffold(
      body: MetricChipBar<_Demo>(
        items: const [
          MetricChip(value: _Demo.a, label: 'IMC'),
          MetricChip(value: _Demo.b, label: 'ICA'),
          MetricChip(value: _Demo.c, label: 'Cintura'),
        ],
        selected: selected,
        onSelected: onSelected,
        family: _family,
      ),
    ),
  );
}

void main() {
  testWidgets('dibuja un chip por cada opción', (tester) async {
    await tester.pumpWidget(_host(selected: _Demo.a, onSelected: (_) {}));

    expect(find.text('IMC'), findsOneWidget);
    expect(find.text('ICA'), findsOneWidget);
    expect(find.text('Cintura'), findsOneWidget);
  });

  testWidgets('la zona táctil de cada chip llega al mínimo accesible', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: _Demo.a, onSelected: (_) {}));

    for (final label in const ['IMC', 'ICA', 'Cintura']) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(
        size.height,
        greaterThanOrEqualTo(44),
        reason: 'El chip «$label» quedó por debajo de la zona táctil mínima.',
      );
    }
  });

  testWidgets('tocar un chip informa su valor', (tester) async {
    _Demo? picked;
    await tester.pumpWidget(
      _host(selected: _Demo.a, onSelected: (v) => picked = v),
    );

    await tester.tap(find.text('Cintura'));
    expect(picked, _Demo.c);
  });

  testWidgets('el chip elegido y el resto no se pintan igual', (tester) async {
    await tester.pumpWidget(_host(selected: _Demo.a, onSelected: (_) {}));

    Color chipColor(String label) {
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration as BoxDecoration).color!;
    }

    // El elegido va en el acento de la familia; el resto, en la superficie
    // hundida del tema. Son distintos por construcción, y esa diferencia es la
    // que comunica cuál está activo.
    expect(chipColor('IMC'), _family.accent);
    expect(chipColor('ICA'), isNot(_family.accent));
  });
}
