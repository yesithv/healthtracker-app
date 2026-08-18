import 'package:flutter/material.dart';

import '../../../../core/widgets/icon_badge.dart';
import '../view_models/med_view_models.dart';

/// La pastilla de color detrás del icono de un medicamento. Envuelve
/// [IconBadge] (que fija la FORMA de la caja desde el tema) y sólo resuelve el
/// COLOR decorativo del medicamento contra el tema activo.
class MedIcon extends StatelessWidget {
  const MedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final MedColor color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tone = resolveMedTone(context, color);
    return IconBadge(
      icon,
      color: tone.accent,
      background: tone.surface,
      size: size,
      iconSize: iconSize,
    );
  }
}
