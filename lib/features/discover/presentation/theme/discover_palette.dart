import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/content_palette.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../data/models/discover_models.dart';

/// Visual identity for a Discover category: an accent colour, a soft tint for
/// backgrounds and an icon. Driving the look from the category key (instead of
/// bundled images) keeps the feed vibrant *and* instant — there are no network
/// images to wait on.
///
/// El COLOR ya no vive aquí. Antes esta clase tenía seis hexadecimales escritos
/// a mano, así que «Descubre» era la única sección de la app que se veía igual
/// pasara lo que pasara con el tema. Ahora el color lo pone [ContentPalette] y
/// esto se queda con lo que de verdad es suyo: el ICONO de cada categoría, que
/// no cambia entre temas, y la forma de derivar tinte y degradado.
class CategoryStyle {
  final Tone tone;
  final IconData icon;

  const CategoryStyle(this.tone, this.icon);

  Color get accent => tone.accent;

  /// A translucent tint of the accent for card backgrounds.
  Color tint([double alpha = 0.12]) => accent.withValues(alpha: alpha);

  /// A two-stop gradient used on hero / featured surfaces.
  LinearGradient gradient() => LinearGradient(
    colors: [accent, Color.lerp(accent, Colors.black, 0.22)!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Central mapping from taxonomy keys (shared with the backoffice) to styles.
class DiscoverPalette {
  const DiscoverPalette._();

  /// Icono de cada categoría. Es lo único que NO depende del tema: cambiar de
  /// aspecto no debería cambiar qué dibujo representa «sueño».
  static const Map<String, IconData> _icons = {
    'heart': Icons.favorite_rounded,
    'nutrition': Icons.restaurant_rounded,
    'emotional': Icons.self_improvement_rounded,
    'sports': Icons.directions_run_rounded,
    'sleep': Icons.nightlight_round,
    'daily': Icons.wb_sunny_rounded,
  };

  static const IconData _fallbackIcon = Icons.auto_stories_rounded;

  static CategoryStyle of(BuildContext context, String category) {
    final theme = Theme.of(context);
    final parsed = ContentPalette.tryParse(category);
    // Categoría que la app aún no conoce (el backoffice puede publicar una
    // antes): se pinta con la marca, que siempre existe, en vez de fallar.
    final tone = parsed == null
        ? Tone.from(theme.surfaces.brand, canvas: theme.surfaces.card)
        : theme.content.tone(parsed);
    return CategoryStyle(tone, _icons[category] ?? _fallbackIcon);
  }

  /// Acento de la sección cuando no cuelga de una categoría concreta.
  static Color brandOf(BuildContext context) =>
      Theme.of(context).surfaces.brand;

  /// Icon shown on the category filter chips.
  static IconData chipIcon(String key) {
    if (key == 'all') return Icons.grid_view_rounded;
    return _icons[key] ?? _fallbackIcon;
  }

  // --- level styling -------------------------------------------------------

  static Tone levelTone(BuildContext context, ContentLevel level) {
    return Theme.of(context).content.level(switch (level) {
      ContentLevel.principiante => ContentLevelStep.easy,
      ContentLevel.intermedio => ContentLevelStep.medium,
      ContentLevel.avanzado => ContentLevelStep.hard,
    });
  }

  // --- challenge status styling -------------------------------------------

  static Tone statusTone(BuildContext context, ChallengeStatus status) {
    return Theme.of(context).content.status(switch (status) {
      ChallengeStatus.activo => ContentStatus.active,
      ChallengeStatus.programado => ContentStatus.scheduled,
      ChallengeStatus.finalizado => ContentStatus.closed,
    });
  }
}
