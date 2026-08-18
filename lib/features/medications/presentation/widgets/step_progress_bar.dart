import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Barra de progreso por segmentos del asistente de alta: un tramo por paso,
/// relleno con el color de marca hasta el paso actual (inclusive).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.total,
    required this.current, // 1-based
  });

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? surfaces.brand : surfaces.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
