import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/pending_account.dart';
import '../providers/user_profile_provider.dart';
import '../theme/theme_context.dart';
import '../../l10n/generated/app_localizations.dart';

/// Aviso de que la cuenta aún no existe en el servidor.
///
/// Se muestra solo mientras el alta está pendiente. No es decorativo: el usuario
/// tiene que saber que sus registros viven únicamente en este dispositivo, y
/// poder forzar el intento sin ir a buscarlo a un submenú.
///
/// No se pinta con el tono de ALERTA de la paleta clínica: no hay nada mal en su
/// salud, y gastar el rojo aquí le quitaría fuerza donde sí significa algo. Usa
/// `caution`, que es exactamente esto — algo que merece atención sin alarmar.
class PendingAccountBanner extends StatefulWidget {
  const PendingAccountBanner({super.key});

  @override
  State<PendingAccountBanner> createState() => _PendingAccountBannerState();
}

class _PendingAccountBannerState extends State<PendingAccountBanner> {
  static const bool _busy = false;
  static const String? _notice = null;

  /// Lleva a la puerta con el correo ya escrito.
  ///
  /// Antes este botón creaba la cuenta desde aquí. Ya no puede: una cuenta nace cuando alguien
  /// demuestra que ese buzón es suyo, y eso ocurre en la puerta. Lo que queda es acompañar.
  void _createNow() {
    final profile = Provider.of<UserProfileProvider>(context, listen: false);
    goToAccessDoor(context, email: profile.userEmail.trim());
  }

  @override
  Widget build(BuildContext context) {
    // `watch`: al crearse la cuenta el aviso debe desaparecer solo.
    final pending = context.watch<PendingAccountStore>();
    if (!pending.isPending) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final tone = theme.clinical.caution;

    return Container(
      // El margen inferior viaja con el aviso: así la pantalla que lo coloca no
      // tiene que dejar un hueco que sobraría cuando está oculto.
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: tone.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.pendingAccountTitle,
                  style: theme.type.cardTitle.copyWith(color: tone.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _notice ?? l10n.pendingAccountBody,
            style: theme.type.body.copyWith(fontSize: 13, color: tone.accent),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tone.accent,
                foregroundColor: tone.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(surfaces.radiusControl),
                ),
              ),
              onPressed: _busy ? null : _createNow,
              child: Text(
                _busy
                    ? l10n.pendingAccountCreating
                    : l10n.pendingAccountCreateNow,
                textAlign: TextAlign.center,
                style: theme.type.button.copyWith(color: tone.onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
