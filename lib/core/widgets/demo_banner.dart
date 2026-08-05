import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../demo/demo_actions.dart';
import '../demo/demo_session.dart';
import '../theme/theme_context.dart';
import '../../l10n/generated/app_localizations.dart';

/// Aviso permanente de que lo que se está viendo es una demostración.
///
/// Va en la cáscara de la app, encima de las cuatro pestañas, y no se puede
/// cerrar. Es deliberado: enseñar datos clínicos inventados sin decirlo en todo
/// momento es justo lo que no se debe hacer, y además es donde el visitante
/// espera encontrar la salida cuando se canse de mirar.
///
/// Se pinta en el tono `info` de la paleta clínica —la familia fría—, no en
/// `caution`: no hay nada que corregir ni que vigilar, es una nota de contexto.
/// Gastar el ámbar aquí le quitaría fuerza donde sí significa algo.
class DemoBanner extends StatefulWidget {
  const DemoBanner({super.key});

  @override
  State<DemoBanner> createState() => _DemoBannerState();
}

class _DemoBannerState extends State<DemoBanner> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // El aviso largo se enseña UNA vez, al llegar al panel recién entrado. Va
    // tras el primer fotograma porque `showDialog` necesita el árbol montado, y
    // quien decide si toca es la sesión —no este widget— para que recargar la
    // página no vuelva a interrumpir a quien ya lo leyó.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && DemoSession.instance.consumeNotice()) _showNotice();
    });
  }

  Future<void> _showNotice() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
        ),
        icon: Icon(
          Icons.science_outlined,
          color: theme.clinical.info.accent,
          size: 32,
        ),
        title: Text(
          l10n.demoNoticeTitle,
          textAlign: TextAlign.center,
          style: theme.type.cardTitle,
        ),
        content: Text(
          l10n.demoNoticeBody,
          textAlign: TextAlign.center,
          style: theme.type.body.copyWith(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: surfaces.brand,
              foregroundColor: surfaces.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(surfaces.radiusControl),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.demoNoticeAction,
              style: theme.type.button.copyWith(color: surfaces.onBrand),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await exitDemo(context);
    // Sin `mounted` no se toca: al salir, esta cáscara ya se ha desmontado.
    if (mounted) setState(() => _leaving = false);
  }

  @override
  Widget build(BuildContext context) {
    // `watch`: al salir, el aviso tiene que desaparecer solo.
    if (!context.watch<DemoSession>().isActive) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tone = theme.clinical.info;

    return Material(
      color: tone.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Icon(Icons.science_outlined, color: tone.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.demoBannerLabel,
                  style: theme.type.badge.copyWith(
                    color: tone.accent,
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton(
                onPressed: _leaving ? null : _leave,
                style: TextButton.styleFrom(
                  foregroundColor: tone.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.demoExit,
                  style: theme.type.button.copyWith(
                    color: tone.accent,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
