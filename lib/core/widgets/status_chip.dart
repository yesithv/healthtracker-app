import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens/clinical_palette.dart';
import '../theme/tokens/tone.dart';

/// Insignia de estado clínico.
///
/// Recibe el SIGNIFICADO ([ClinicalStatus]) y no un color. El tema activo decide
/// el acabado: relleno sólido en «Pulso Clínico», relleno suave en «Consulta
/// Serena». Por eso este widget es el único sitio de la app que sabe cómo se
/// dibuja una insignia, y cambiar ese idioma en un tema no obliga a tocar
/// ninguna pantalla.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  /// Estado clínico que se comunica. Lo produce el clasificador
  /// (`BpCategory.of(...).status`), nunca la pantalla a ojo.
  final ClinicalStatus status;

  /// Texto ya localizado.
  final String label;

  /// Icono opcional. Refuerza el estado para quien no distingue los colores:
  /// el color nunca debe ser el único portador de la información.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinical = theme.clinical;
    final tone = clinical.tone(status);
    final isSolid = clinical.badgeIdiom == BadgeIdiom.solid;

    final Color background = isSolid ? tone.accent : tone.surface;
    final Color foreground = isSolid ? tone.onAccent : tone.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(label, style: theme.type.badge.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Icono canónico de cada estado. Vive junto a la insignia para que el par
/// color+forma se decida en un solo sitio y sea idéntico en toda la app.
IconData iconForStatus(ClinicalStatus status) => switch (status) {
  ClinicalStatus.info => Icons.arrow_downward_rounded,
  ClinicalStatus.optimal => Icons.check_circle_outline_rounded,
  ClinicalStatus.caution => Icons.warning_amber_rounded,
  ClinicalStatus.alert => Icons.report_outlined,
  ClinicalStatus.neutral => Icons.remove_rounded,
};
