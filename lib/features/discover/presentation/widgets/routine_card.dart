import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/discover_models.dart';
import '../theme/discover_palette.dart';

/// Compact card for the horizontal "Rutinas" rail: level badge, title, and a
/// duration / exercise-count meta line.
class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;

  const RoutineCard({super.key, required this.routine, required this.onTap});

  String _levelLabel(AppLocalizations l10n, ContentLevel level) {
    switch (level) {
      case ContentLevel.principiante:
        return l10n.discoverLevelBeginner;
      case ContentLevel.intermedio:
        return l10n.discoverLevelIntermediate;
      case ContentLevel.avanzado:
        return l10n.discoverLevelAdvanced;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = DiscoverPalette.of(routine.category);
    final levelColor = DiscoverPalette.levelColor(routine.level);

    return SizedBox(
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: style.tint(),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(style.icon, color: style.accent, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _levelLabel(l10n, routine.level),
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    routine.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    routine.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: style.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${routine.durationMin} ${l10n.discoverMinShort}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      if (routine.exercises > 0) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.fitness_center_rounded,
                            size: 14, color: style.accent),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.discoverExercises('${routine.exercises}'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
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
          ),
        ),
      ),
    );
  }
}
