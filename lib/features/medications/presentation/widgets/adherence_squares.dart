import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../view_models/med_view_models.dart';

/// Fila compacta de cuadros de estado de los últimos días (la usa la tarjeta de
/// adherencia del detalle). Verde = tomado, ámbar = omitido, hueco = sin dato.
class AdherenceSquares extends StatelessWidget {
  const AdherenceSquares({super.key, required this.days});

  /// Estado por día, del más antiguo al más reciente. `null` = sin dato.
  final List<DoseState?> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _Square(state: s),
            ),
          ),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.state});

  final DoseState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    final color = switch (state) {
      DoseState.taken => theme.clinical.tone(ClinicalStatus.optimal).accent,
      DoseState.skipped => theme.clinical.tone(ClinicalStatus.alert).surface,
      DoseState.pending => surfaces.inset,
      null => surfaces.inset,
    };

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(surfaces.radiusIcon * 0.7),
      ),
    );
  }
}
