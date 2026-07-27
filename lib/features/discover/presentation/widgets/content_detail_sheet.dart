import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// A single, reusable reader sheet for any Discover item (article, routine or
/// challenge). Because all content is already in memory, this opens instantly —
/// there is no network round-trip and therefore no loading state.
Future<void> showDiscoverDetailSheet(
  BuildContext context, {
  required Color accent,
  required IconData icon,
  required String kicker,
  required String title,
  required String body,
  List<Widget> chips = const [],
  String? ctaLabel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final surfaces = theme.surfaces;
          // La cabecera va sobre el acento sólido de la categoría, así que su
          // contenido se pinta con el `onAccent` del tema y no con blanco.
          final on = surfaces.onBrand;
          final radius = Radius.circular(surfaces.radiusCard + 8);
          return Container(
            decoration: BoxDecoration(
              color: surfaces.inset,
              borderRadius: BorderRadius.vertical(top: radius),
            ),
            child: Column(
              children: [
                // Coloured header.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, Color.lerp(accent, Colors.black, 0.22)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: on.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: on.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: on, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            kicker.toUpperCase(),
                            style: theme.type.sectionLabel.copyWith(
                              color: on.withValues(alpha: 0.9),
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: theme.type.screenTitle.copyWith(
                          color: on,
                          fontSize: 22,
                          height: 1.25,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: chips),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                    children: [
                      Text(
                        body,
                        style: theme.type.body.copyWith(
                          fontSize: 15.5,
                          height: 1.6,
                          color: surfaces.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ctaLabel != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: on,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              surfaces.radiusControl,
                            ),
                          ),
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Small pill used inside the detail header (meta chips).
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const DetailChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Vive dentro de la cabecera de color, así que se pinta con el mismo
    // `onBrand` que el resto de esa cabecera.
    final on = theme.surfaces.onBrand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: on.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: on),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.type.badge.copyWith(color: on, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
