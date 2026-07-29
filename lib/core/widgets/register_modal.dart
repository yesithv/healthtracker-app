import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens/metric_palette.dart';
import 'icon_badge.dart';

/// Shows the register modal with a blurred background.
void showRegisterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    enableDrag: true,
    builder: (context) => const _RegisterModalContent(),
  );
}

class _RegisterModalContent extends StatelessWidget {
  const _RegisterModalContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(surfaces.radiusCard + 8),
          topRight: Radius.circular(surfaces.radiusCard + 8),
        ),
        boxShadow: surfaces.glow(
          Colors.black,
          alpha: 0.2,
          blur: 30,
          offset: const Offset(0, -6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surfaces.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.registerIndicators,
                    style: theme.type.sectionLabel.copyWith(
                      color: surfaces.brand,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: IconBadge(
                      Icons.close,
                      color: surfaces.inkSecondary,
                      background: surfaces.inset,
                      padding: 5,
                      iconSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // LISTADO, no rejilla. En dos columnas los rótulos largos
              // («Body Composition», «Antropometría») partían en dos o tres
              // líneas y cada tarjeta quedaba de una altura distinta. A lo
              // ancho, el texto cabe entero y las cuatro filas se recorren de
              // arriba abajo, que es como se lee una lista de opciones.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RegisterOption(
                    icon: Icons.straighten,
                    label: l10n.anthropometry,
                    family: MetricFamily.anthropometry,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/record-anthropometric');
                    },
                  ),
                  const SizedBox(height: 10),
                  _RegisterOption(
                    icon: Icons.favorite,
                    label: l10n.vitalSigns,
                    family: MetricFamily.vitals,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/record-vital-signs');
                    },
                  ),
                  const SizedBox(height: 10),
                  _RegisterOption(
                    icon: Icons.bloodtype,
                    label: l10n.lipidProfile,
                    family: MetricFamily.lipids,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/record-lipid');
                    },
                  ),
                  const SizedBox(height: 10),
                  _RegisterOption(
                    icon: Icons.accessibility_new,
                    label: l10n.bodyComposition,
                    family: MetricFamily.bodyComposition,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/record-body-composition');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterOption extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Familia del indicador. La tarjeta pide la IDENTIDAD y el tema resuelve el
  /// color: así el rojo del corazón sigue siendo rojo en cualquier tema.
  final MetricFamily family;
  final VoidCallback onTap;

  const _RegisterOption({
    required this.icon,
    required this.label,
    required this.family,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = theme.metrics.tone(family);
    final radius = theme.surfaces.radiusCard;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            IconBadge(
              icon,
              color: tone.accent,
              background: tone.accent.withValues(alpha: 0.15),
              size: 40,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                // Una sola línea: a lo ancho siempre cabe, y si algún idioma
                // trae un rótulo larguísimo se recorta en vez de descuadrar la
                // fila.
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.type.cardTitle.copyWith(
                  fontSize: 15,
                  color: tone.accent,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: tone.accent.withValues(alpha: 0.55),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
