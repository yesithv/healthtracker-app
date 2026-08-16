import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Contenedor común de una gráfica de tendencia de historial: título del
/// indicador a la izquierda, insignia del periodo a la derecha, la gráfica de alto
/// fijo (180) y su leyenda debajo.
///
/// Signos vitales ya tenía este andamiaje como `_chartCard`; antropometría lo
/// reimplementaba en línea dentro de su `_buildChartContainer`. Aquí vive una sola
/// vez: cada `chartBuilder` solo aporta [title], la [chart] y su [legend].
class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    super.key,
    required this.title,
    required this.filterLabel,
    required this.chart,
    required this.legend,
  });

  final String title;
  final String filterLabel;
  final Widget chart;
  final Widget legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: theme.type.sectionLabel.copyWith(
                    fontSize: 11,
                    color: surfaces.inkSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: surfaces.inset,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filterLabel,
                  style: theme.type.badge.copyWith(
                    fontSize: 10,
                    color: surfaces.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(height: 180, child: chart),
          const SizedBox(height: 16),
          legend,
        ],
      ),
    );
  }
}
