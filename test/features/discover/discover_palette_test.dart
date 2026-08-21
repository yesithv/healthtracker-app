import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/discover/presentation/theme/discover_palette.dart';

/// `chipIcon` es la parte de la paleta de «Descubre» que NO depende del tema ni
/// del `BuildContext`: traduce la clave de taxonomía de cada chip de filtro a su
/// icono. Es también la que se rompe en silencio si el backoffice publica una
/// categoría que la app aún no conoce —saldría sin icono en vez de con uno de
/// respaldo—, así que conviene fijar el contrato: claves conocidas → su icono,
/// el chip especial `all` → la rejilla, y cualquier otra cosa → el respaldo.
void main() {
  group('DiscoverPalette.chipIcon ·', () {
    test('el chip especial "all" usa la rejilla', () {
      expect(DiscoverPalette.chipIcon('all'), Icons.grid_view_rounded);
    });

    test('cada categoría conocida tiene su icono', () {
      expect(DiscoverPalette.chipIcon('heart'), Icons.favorite_rounded);
      expect(DiscoverPalette.chipIcon('nutrition'), Icons.restaurant_rounded);
      expect(DiscoverPalette.chipIcon('emotional'), Icons.self_improvement_rounded);
      expect(DiscoverPalette.chipIcon('sports'), Icons.directions_run_rounded);
      expect(DiscoverPalette.chipIcon('sleep'), Icons.nightlight_round);
    });

    test('una categoría desconocida cae al icono de respaldo, no a null', () {
      expect(DiscoverPalette.chipIcon('categoria-nueva'), Icons.auto_stories_rounded);
      expect(DiscoverPalette.chipIcon(''), Icons.auto_stories_rounded);
    });
  });
}
