import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Hasta cuándo llega la historia que la clínica trajo de su sistema.
///
/// <h3>Por qué se enseña siempre y no solo cuando falla</h3>
///
/// Una historia clínica migrada **tiene** una fecha de corte, funcione o no el sincronizador: lo
/// que se ve en la app es una copia de lo que hay en el sistema de la clínica a una fecha. Un dato
/// que apareciera únicamente cuando algo va mal se leería como una alarma; presente siempre, es
/// contexto, y el día que se atrasa solo cambia de tono.
///
/// <h3>Y por qué se enseña</h3>
///
/// Sin esto, un sincronizador parado se ve exactamente igual que uno al día: los mismos datos, sin
/// nada que diga que son de hace una semana. Es la misma clase de silencio que la Fase 7 quitó de
/// los textos legales —afirmar de más por omisión— aplicada a los números.
///
/// No aparece para quien no viene de la clínica: no hay nada que fechar.
class ClinicDataFreshness extends StatelessWidget {
  /// A partir de cuántos días deja de ser contexto y pasa a ser un aviso.
  ///
  /// Dos: la corrida del servidor es diaria, así que un día de retraso entra dentro de lo normal
  /// —una corrida que llega tarde— y dos ya no.
  static const int staleAfterDays = 2;

  const ClinicDataFreshness({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>();
    final syncedAt = profile.clinicDataSyncedAt;
    if (syncedAt == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;

    final days = profile.clinicDataAgeDays ?? 0;
    final stale = days >= staleAfterDays;
    final color = stale ? clinical.caution.accent : surfaces.inkMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            stale ? Icons.schedule_rounded : Icons.cloud_done_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stale
                  ? l10n.clinicDataStale(_formatDate(syncedAt), days)
                  : l10n.clinicDataUpToDate(_formatDate(syncedAt)),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: color,
                fontWeight: stale ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fecha corta y local. No se usa `intl` con locale aquí porque el rótulo entero viene de
  /// l10n y esto es solo el número dentro.
  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
