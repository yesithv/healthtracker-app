import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Resultado de un intento de compartir/exportar, ya reducido a lo que la interfaz
/// necesita decidir: enseñar «hecho», callar, o avisar de un fallo.
///
/// Nació para arreglar dos bugs reales de las exportaciones: (1) cancelar el
/// diálogo de compartir contaba como éxito, porque `SharePlus.share` no lanza al
/// cancelar y el código devolvía `true` a secas; y (2) los export PDF/CSV del
/// historial no capturaban errores ni confirmaban nada.
enum ShareOutcome {
  /// El sistema confirmó que se compartió/guardó.
  success,

  /// Sin confirmación accionable: el usuario canceló el diálogo. No es un error,
  /// así que NO se muestra ni éxito ni fallo.
  silent,

  /// Falló de verdad (excepción, o «no disponible» en una plataforma donde eso
  /// significa que no hay con qué compartir).
  error,
}

/// Traduce el `ShareResult` de share_plus a [ShareOutcome].
///
/// `unavailable` es ambiguo y depende de la plataforma: en **web** el guardado de
/// un archivo se hace por descarga y la plataforma no puede confirmar estado, pero
/// el archivo ya bajó → lo tratamos como éxito; en **móvil** significa que no hay
/// nada con qué compartir → es un error.
ShareOutcome shareOutcomeOf(ShareResult result) {
  switch (result.status) {
    case ShareResultStatus.success:
      return ShareOutcome.success;
    case ShareResultStatus.dismissed:
      return ShareOutcome.silent;
    case ShareResultStatus.unavailable:
      return kIsWeb ? ShareOutcome.success : ShareOutcome.error;
  }
}

/// Ejecuta un share y devuelve el [ShareOutcome], capturando cualquier excepción
/// como [ShareOutcome.error].
Future<ShareOutcome> runShare(Future<ShareResult> Function() action) async {
  try {
    return shareOutcomeOf(await action());
  } catch (e) {
    debugPrint('Error al compartir: $e');
    return ShareOutcome.error;
  }
}

/// Muestra el snackbar que corresponde al resultado. Silencioso cuando el usuario
/// canceló. Captura el `ScaffoldMessengerState` ANTES del `await` en quien llama,
/// para no leer el `BuildContext` tras un hueco asíncrono.
void showShareFeedback(
  ScaffoldMessengerState messenger,
  ThemeData theme,
  AppLocalizations l10n,
  ShareOutcome outcome, {
  String? successMessage,
}) {
  final clinical = theme.clinical;
  switch (outcome) {
    case ShareOutcome.silent:
      return;
    case ShareOutcome.success:
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage ?? l10n.exportSuccess),
          backgroundColor: clinical.optimal.accent,
        ),
      );
      return;
    case ShareOutcome.error:
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.exportError),
          backgroundColor: clinical.alert.accent,
        ),
      );
      return;
  }
}
