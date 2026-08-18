import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'register_dose_sheet.dart';

/// Hoja «Activa los recordatorios»: solicitud de permiso de notificaciones. El
/// botón principal pide el permiso real al sistema
/// ([NotificationService.requestPermissions]); «Ahora no» solo cierra la hoja.
Future<void> showNotificationsPermissionSheet(BuildContext context) {
  final surfaces = Theme.of(context).surfaces;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaces.canvas,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(surfaces.radiusCard),
      ),
    ),
    builder: (_) => const _NotificationsPermissionSheet(),
  );
}

class _NotificationsPermissionSheet extends StatelessWidget {
  const _NotificationsPermissionSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final caution = theme.clinical.tone(ClinicalStatus.caution);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            medSheetGrabber(context),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: caution.surface,
                borderRadius: BorderRadius.circular(surfaces.radiusIcon),
              ),
              child: Icon(Icons.notifications, size: 36, color: caution.accent),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.medNotifTitle,
              style: theme.type.screenTitle.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.medNotifBody,
              style: theme.type.body.copyWith(color: surfaces.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaces.inset,
                borderRadius: BorderRadius.circular(surfaces.radiusControl),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: caution.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.medNotifWebWarning, style: theme.type.meta),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: MedSheetButton(
                label: l10n.medAllowNotifications,
                solid: true,
                color: surfaces.brand,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await NotificationService().requestPermissions();
                  navigator.pop();
                },
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.medNotNow,
                style: theme.type.button.copyWith(color: surfaces.inkSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
