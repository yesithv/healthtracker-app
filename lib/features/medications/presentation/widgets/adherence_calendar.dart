import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../view_models/med_view_models.dart';

/// Calendario mensual de adherencia: rejilla de 7 columnas con un cuadro de
/// estado por día y una leyenda. Las iniciales de día y las etiquetas de la
/// leyenda llegan ya localizadas desde la pantalla.
class AdherenceCalendar extends StatelessWidget {
  const AdherenceCalendar({
    super.key,
    required this.monthLabel,
    required this.days,
    required this.weekdayInitials,
    required this.takenLabel,
    required this.skippedLabel,
    required this.noDataLabel,
  });

  final String monthLabel;
  final List<AdherenceDayVm> days;

  /// Iniciales de lunes a domingo, ya localizadas (7 elementos).
  final List<String> weekdayInitials;
  final String takenLabel;
  final String skippedLabel;
  final String noDataLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel, style: theme.type.cardTitle),
              Row(
                children: [
                  Icon(Icons.chevron_left, size: 20, color: surfaces.inkMuted),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: surfaces.inkMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in weekdayInitials)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: theme.type.meta.copyWith(fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [for (final d in days) _DayCell(day: d)],
          ),
          const SizedBox(height: 14),
          _Legend(
            takenLabel: takenLabel,
            skippedLabel: skippedLabel,
            noDataLabel: noDataLabel,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day});

  final AdherenceDayVm day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    final Color bg;
    final Color fg;
    if (day.isToday) {
      bg = surfaces.brand;
      fg = surfaces.onBrand;
    } else {
      switch (day.state) {
        case DoseState.taken:
          final t = theme.clinical.tone(ClinicalStatus.optimal);
          bg = t.accent;
          fg = t.onAccent;
        case DoseState.skipped:
          final t = theme.clinical.tone(ClinicalStatus.alert);
          bg = t.surface;
          fg = t.accent;
        case DoseState.pending:
        case null:
          bg = surfaces.inset;
          fg = surfaces.inkMuted;
      }
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(surfaces.radiusIcon),
      ),
      child: Text(
        '${day.number}',
        style: theme.type.numeralSmall.copyWith(
          fontSize: 13,
          color: day.outOfMonth ? fg.withValues(alpha: 0.5) : fg,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.takenLabel,
    required this.skippedLabel,
    required this.noDataLabel,
  });

  final String takenLabel;
  final String skippedLabel;
  final String noDataLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final taken = theme.clinical.tone(ClinicalStatus.optimal).accent;
    final skipped = theme.clinical.tone(ClinicalStatus.alert).surface;

    return Row(
      children: [
        _LegendItem(color: taken, label: takenLabel),
        const SizedBox(width: 18),
        _LegendItem(color: skipped, label: skippedLabel),
        const SizedBox(width: 18),
        _LegendItem(color: surfaces.inset, label: noDataLabel),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.type.meta.copyWith(fontSize: 12)),
      ],
    );
  }
}
