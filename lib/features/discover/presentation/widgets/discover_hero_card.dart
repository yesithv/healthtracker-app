import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The bold, colourful daily-tip hero at the top of Discover. Replaces the old
/// pale tinted card with a rich gradient, a decorative glow and a clear CTA.
class DiscoverHeroCard extends StatelessWidget {
  final String tip;
  final VoidCallback? onReadMore;

  const DiscoverHeroCard({super.key, required this.tip, this.onReadMore});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final brand = surfaces.brand;
    final onBrand = surfaces.onBrand;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // El degradado se deriva de la marca en vez de llevar dos azules
        // escritos a mano: aclarar el propio acento funciona en cualquier tema.
        gradient: LinearGradient(
          // El segundo tramo es la marca aclarada un 22 %, no un color
          // de interfaz: por eso se mezcla con blanco puro.
          colors: [brand, Color.lerp(brand, Colors.white, 0.22)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(surfaces.radiusCard + 6),
        boxShadow: surfaces.cardShadow.isEmpty ? const [] : [
          BoxShadow(
            color: brand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative glow in the corner.
          Positioned(
            right: -24,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onBrand.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: onBrand.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.wb_sunny_rounded,
                        color: onBrand, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.discoverDailyTip.toUpperCase(),
                    style: theme.type.sectionLabel.copyWith(
                      fontSize: 11,
                      color: onBrand.withValues(alpha: 0.9),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tip,
                style: theme.type.cardTitle.copyWith(
                  fontSize: 18,
                  height: 1.35,
                  color: onBrand,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: onBrand,
                borderRadius: BorderRadius.circular(surfaces.radiusControl),
                child: InkWell(
                  borderRadius: BorderRadius.circular(surfaces.radiusControl),
                  onTap: onReadMore,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.discoverReadMore,
                          style: theme.type.button.copyWith(
                            color: brand,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: brand, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
