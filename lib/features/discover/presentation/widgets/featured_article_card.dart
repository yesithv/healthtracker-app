import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/article.dart';
import '../theme/discover_palette.dart';

/// Large, image-free "magazine" card for the featured rail: a full-bleed accent
/// gradient, a big icon watermark and the article headline.
class FeaturedArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const FeaturedArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final style = DiscoverPalette.of(context, article.category);
    // Todo lo de dentro va sobre el acento sólido de la categoría, así que se
    // pinta con SU `onAccent` en vez de blanco: si un tema usara un acento
    // claro para alguna categoría, esto seguiría siendo legible.
    final on = style.tone.onAccent;

    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: style.gradient(),
              borderRadius: BorderRadius.circular(22),
              boxShadow: surfaces.glow(
                style.accent,
                alpha: 0.30,
                blur: 18,
                offset: const Offset(0, 10),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Icon(
                    style.icon,
                    size: 130,
                    color: on.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: on.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.discoverFeatured.toUpperCase(),
                          style: theme.type.cardTitle.copyWith(
                            color: on,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      Text(
                        article.title,
                        style: theme.type.cardTitle.copyWith(
                          color: on,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.subtitle,
                        style: TextStyle(
                          color: on.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: on),
                          const SizedBox(width: 5),
                          Text(
                            '${article.readTime} ${l10n.discoverMinRead}',
                            style: theme.type.cardTitle.copyWith(
                              color: on,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
