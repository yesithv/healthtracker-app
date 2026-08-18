import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../view_models/med_view_models.dart';

/// Tira horizontal de la semana con un punto de estado bajo cada día (la
/// variante «1b» del prototipo). El día de hoy va relleno con el color de marca.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days});

  final List<WeekDayVm> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (final d in days) _DayColumn(day: d)],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day});

  final WeekDayVm day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    final dotColor = switch (day.state) {
      DoseState.taken => theme.clinical.tone(ClinicalStatus.optimal).accent,
      DoseState.skipped => theme.clinical.tone(ClinicalStatus.caution).accent,
      DoseState.pending => surfaces.inkMuted,
    };

    return Column(
      children: [
        Text(
          day.weekday,
          style: theme.type.meta.copyWith(
            fontSize: 11,
            color: day.isToday ? surfaces.brand : surfaces.inkMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: day.isToday ? surfaces.brand : surfaces.inset,
          ),
          child: Text(
            '${day.number}',
            style: theme.type.numeralSmall.copyWith(
              fontSize: 14,
              color: day.isToday ? surfaces.onBrand : surfaces.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: day.isToday ? Colors.transparent : dotColor,
          ),
        ),
      ],
    );
  }
}
