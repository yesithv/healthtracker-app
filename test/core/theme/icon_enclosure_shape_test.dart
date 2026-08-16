// UN ICONO ENCERRADO VA EN UN CUADRADO REDONDEADO, NUNCA EN UN CÍRCULO.
//
// La app tenía las dos formas conviviendo sin criterio. El menú de Historial
// dibujaba la caja de sus iconos con `BorderRadius.circular(10)`; la hoja de
// «Registrar indicadores», que muestra exactamente los mismos cuatro
// indicadores con la misma anatomía de fila, la dibujaba con
// `shape: BoxShape.circle`. Entrar por un sitio o por otro daba dos apps
// distintas, y no había dónde mirar para saber cuál era la buena.
//
// Ahora la forma la pone `surfaces.radiusIcon` y la monta `IconBadge`. Esta
// prueba impide que se vuelva a colar un círculo: cualquier `BoxShape.circle`
// en `lib/` tiene que estar INVENTARIADO abajo, con su razón escrita.
//
// El inventario no es una lista de excepciones toleradas; es la lista de cosas
// que de verdad son redondas y que nada tienen que ver con encerrar un icono:
// un avatar, el punto de un radio, la perilla de un deslizador, un adorno del
// fondo. Si al añadir una pantalla salta esta prueba, la pregunta no es «¿cómo
// la callo?» sino «¿esto encierra un icono?». Si lo encierra, usa `IconBadge`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Círculos legítimos, por fichero, con el número exacto que le toca a cada uno.
/// El número está a propósito: añadir un círculo más al mismo fichero también
/// tiene que doler.
const _legitimateCircles = <String, ({int count, String reason})>{
  'lib/features/profile/presentation/screens/profile_screen.dart': (
    count: 2,
    reason:
        'El aro del avatar y la chapa de cámara que lleva pegada. El avatar es '
        'una FOTO de una persona, no un icono; su chapa es un adorno suyo y '
        'sigue su forma.',
  ),
  'lib/features/onboarding/presentation/screens/onboarding_avatar_page.dart': (
    count: 3,
    reason:
        'El mismo avatar del alta: su resplandor exterior, el aro y la chapa '
        'de cámara.',
  ),
  'lib/features/profile/presentation/screens/language_selection_screen.dart': (
    count: 2,
    reason:
        'El radio de idioma: aro y punto interior. Un radio es redondo por '
        'convención de plataforma, y no encierra ningún icono.',
  ),
  'lib/features/profile/presentation/widgets/unit_of_measure_selection.dart': (
    count: 2,
    reason: 'El radio de unidades: aro y punto, igual que el de idioma.',
  ),
  'lib/features/theming/presentation/widgets/theme_preview_card.dart': (
    count: 1,
    reason:
        'La marca de tema elegido, que es un radio con otra ropa. El icono de '
        'la paleta que va al principio de la fila SÍ usa `IconBadge`.',
  ),
  'lib/features/dashboard/presentation/widgets/composition_indicator_card.dart':
      (
        count: 1,
        reason:
            'La perilla que marca la posición sobre la escala. Es un punto '
            'sobre un riel, no una caja.',
      ),
  'lib/features/discover/presentation/widgets/discover_hero_card.dart': (
    count: 1,
    reason:
        'El halo decorativo de la esquina de la tarjeta. No hay icono dentro: '
        'es una mancha de color del fondo.',
  ),
  'lib/features/history/presentation/widgets/vital_signs_history_tab.dart': (
    count: 1,
    reason:
        'El punto de la leyenda que marca las lecturas con síntoma. Es un '
        'PUNTO redondo que replica el marcador del dato en la gráfica '
        '(FlDotCirclePainter, redondo por convención de fl_chart); no encierra '
        'ningún icono, es la clave de leyenda de ese marcador.',
  ),
};

void main() {
  group('La caja que encierra un icono', () {
    test('ningún círculo sin inventariar en lib/', () {
      final found = <String, int>{};

      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        var count = 0;
        for (final line in file.readAsLinesSync()) {
          final code = line.trimLeft();
          // Los comentarios de documentación nombran `BoxShape.circle` para
          // explicar justamente por qué ya no se usa.
          if (code.startsWith('//')) continue;
          if (line.contains('BoxShape.circle')) count++;
        }
        // Normaliza el separador: el inventario usa `/`, pero en Windows
        // `File.path` devuelve `\` y la clave no casaría.
        if (count > 0) found[file.path.replaceAll(r'\', '/')] = count;
      }

      final problems = <String>[];

      found.forEach((path, count) {
        final allowed = _legitimateCircles[path];
        if (allowed == null) {
          problems.add(
            '\n  $path dibuja $count círculo(s) y no está inventariado.'
            '\n     Si encierra un icono, usa `IconBadge`; el tema pone la forma.'
            '\n     Si de verdad es redondo (avatar, radio, perilla, adorno),'
            '\n     añádelo arriba con su razón.',
          );
        } else if (allowed.count != count) {
          problems.add(
            '\n  $path dibuja $count círculo(s); el inventario dice '
            '${allowed.count}.'
            '\n     Inventariado por: ${allowed.reason}'
            '\n     Si el nuevo encierra un icono, usa `IconBadge`.',
          );
        }
      });

      _legitimateCircles.forEach((path, allowed) {
        if (!found.containsKey(path)) {
          problems.add(
            '\n  $path ya no dibuja ningún círculo: sobra del inventario.',
          );
        }
      });

      expect(problems, isEmpty, reason: problems.join());
    });

    test('las listas de indicadores comparten la misma caja', () {
      // El defecto concreto que motivó todo esto: Historial y la hoja del «+»
      // muestran los mismos cuatro indicadores con la misma fila, y se veían
      // distintos. Las dos tienen que pedir la caja al mismo sitio.
      const listas = [
        'lib/features/history/presentation/screens/history_screen.dart',
        'lib/core/widgets/register_modal.dart',
      ];
      for (final path in listas) {
        final src = File(path).readAsStringSync();
        expect(
          src,
          contains('IconBadge('),
          reason:
              '$path dibuja una lista de indicadores; su icono tiene que ir en '
              '`IconBadge` para que las dos listas se vean igual.',
        );
      }
    });

    test('el radio del icono lo define cada tema', () {
      // Que exista el token no basta: si un tema se olvidara de darle valor no
      // compilaría, pero sí puede colarse un tema que copie el radio de la
      // tarjeta y deje la caja del icono casi redonda.
      // Un tema es un fichero que construye sus propias superficies; el resto
      // de `themes/` son ayudantes (la escala tipográfica, por ejemplo).
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
        final match = RegExp(r'radiusIcon:\s*([\d.]+)').firstMatch(src);
        expect(match, isNotNull, reason: '$path no declara `radiusIcon`.');
        final radius = double.parse(match!.group(1)!);
        expect(
          radius,
          inInclusiveRange(4, 18),
          reason:
              '$path pone `radiusIcon: $radius`. Por debajo de 4 la caja es un '
              'cuadrado seco y por encima de 18 vuelve a leerse como círculo; '
              'en ambos casos deja de parecerse a la del resto de temas.',
        );
      }
    });
  });
}
