import 'package:flutter/material.dart';

import '../../data/models/discover_models.dart';

/// Visual identity for a Discover category: an accent colour, a soft tint for
/// backgrounds and an icon. Driving the look from the category key (instead of
/// bundled images) keeps the feed vibrant *and* instant — there are no network
/// images to wait on.
class CategoryStyle {
  final Color accent;
  final IconData icon;

  const CategoryStyle(this.accent, this.icon);

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

  static const Color brand = Color(0xFF0D48A0);

  static const Map<String, CategoryStyle> _byCategory = {
    'heart': CategoryStyle(Color(0xFFE5484D), Icons.favorite_rounded),
    'nutrition': CategoryStyle(Color(0xFF16A34A), Icons.restaurant_rounded),
    'emotional': CategoryStyle(Color(0xFF7C5CFC), Icons.self_improvement_rounded),
    'sports': CategoryStyle(Color(0xFFF97316), Icons.directions_run_rounded),
    'sleep': CategoryStyle(Color(0xFF4F46E5), Icons.nightlight_round),
    'daily': CategoryStyle(Color(0xFF0EA5A4), Icons.wb_sunny_rounded),
  };

  static const CategoryStyle _fallback =
      CategoryStyle(brand, Icons.auto_stories_rounded);

  static CategoryStyle of(String category) =>
      _byCategory[category] ?? _fallback;

  /// Icon shown on the category filter chips.
  static IconData chipIcon(String key) {
    if (key == 'all') return Icons.grid_view_rounded;
    return of(key).icon;
  }

  // --- level styling -------------------------------------------------------

  static Color levelColor(ContentLevel level) {
    switch (level) {
      case ContentLevel.principiante:
        return const Color(0xFF16A34A);
      case ContentLevel.intermedio:
        return const Color(0xFFF59E0B);
      case ContentLevel.avanzado:
        return const Color(0xFFE5484D);
    }
  }

  // --- challenge status styling -------------------------------------------

  static Color statusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.activo:
        return const Color(0xFF16A34A);
      case ChallengeStatus.programado:
        return const Color(0xFF0EA5A4);
      case ChallengeStatus.finalizado:
        return const Color(0xFF94A3B8);
    }
  }
}
