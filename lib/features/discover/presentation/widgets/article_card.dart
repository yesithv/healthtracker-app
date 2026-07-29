import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/article.dart';
import '../theme/discover_palette.dart';

/// A polished article row: category-coloured icon tile, title, subtitle and a
/// read-time meta line. Replaces the old flat blue-tinted list tile.
class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final style = DiscoverPalette.of(context, article.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: surfaces.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: style.gradient(),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.tone.onAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: theme.type.cardTitle.copyWith(
                          fontSize: 15,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.subtitle,
                        style: theme.type.body.copyWith(
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: style.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.readTime} ${l10n.discoverMinRead}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: style.accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (article.author.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('·', style: theme.type.meta),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                article.author,
                                style: theme.type.body.copyWith(
                                  fontSize: 11,
                                  color: surfaces.inkMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
