import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/export/clinical_summary.dart';
import 'package:myvitals_healthtracker_app/core/export/medical_history_pdf.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Botón primario que dispara el PDF CONSOLIDADO de historia clínica: un solo
/// documento con los cuatro indicadores para enseñar al médico. Va arriba en la
/// pantalla Historia, sobre la lista de módulos.
///
/// Al pulsar abre un selector de periodo (6 meses / 1 año / todo, con «1 año»
/// como recomendado); al elegir, agrega los datos con [buildClinicalSummary],
/// construye el PDF con [buildMedicalHistoryPdf] y lo comparte con
/// [Printing.sharePdf], reutilizando el mismo feedback que los export por-módulo.
class ConsolidatedExportButton extends StatelessWidget {
  const ConsolidatedExportButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusCard);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: surfaces.brand,
        borderRadius: radius,
        child: InkWell(
          onTap: () => _openPeriodSheet(context),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                IconBadge(
                  Icons.summarize_outlined,
                  color: surfaces.onBrand,
                  background: surfaces.onBrand.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mhxButton,
                        style: theme.type.cardTitle.copyWith(
                          fontSize: 15,
                          color: surfaces.onBrand,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.mhxHubHint,
                        style: theme.type.body.copyWith(
                          fontSize: 12,
                          color: surfaces.onBrand.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: surfaces.onBrand.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPeriodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) => _PeriodSheet(
        onSelected: (period) {
          Navigator.of(sheetContext).pop();
          _generate(context, period);
        },
      ),
    );
  }

  /// Lee los cuatro repositorios y el perfil, agrega, construye el PDF y lo
  /// comparte. Captura `messenger`/`theme`/`l10n` ANTES del primer `await` para
  /// no leer el `BuildContext` tras un hueco asíncrono.
  Future<void> _generate(BuildContext context, ExportPeriod period) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).languageCode;

    final profile = context.read<UserProfileProvider>();
    final summary = buildClinicalSummary(
      period: period,
      now: DateTime.now(),
      vitals: context.read<VitalSignsRepository>().items,
      anthropometry: context.read<AnthropometricRepository>().items,
      lipids: context.read<LipidRepository>().items,
      bodyComposition: context.read<BodyCompositionRepository>().items,
    );

    if (!summary.hasData) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.mhxNoData,
            style: theme.type.body.copyWith(color: theme.clinical.info.onAccent),
          ),
          backgroundColor: theme.clinical.info.accent,
        ),
      );
      return;
    }

    final patient = MedicalHistoryPatient(
      name: profile.userName,
      birthDate: profile.birthDate,
      gender: profile.userGender,
    );

    try {
      final bytes = await buildMedicalHistoryPdf(
        summary: summary,
        patient: patient,
        l10n: l10n,
        localeName: localeName,
      );
      final ok = await Printing.sharePdf(
        bytes: bytes,
        filename: 'medical_history.pdf',
      );
      showShareFeedback(
        messenger,
        theme,
        l10n,
        ok ? ShareOutcome.success : ShareOutcome.silent,
      );
    } catch (e) {
      debugLogError('Export.consolidated', e);
      showShareFeedback(messenger, theme, l10n, ShareOutcome.error);
    }
  }
}

/// Hoja de selección de periodo. Cada fila es una acción directa: al tocarla se
/// genera el documento para ese periodo (mismo patrón de una-pulsación que la
/// hoja de «Registrar»).
class _PeriodSheet extends StatelessWidget {
  final ValueChanged<ExportPeriod> onSelected;
  const _PeriodSheet({required this.onSelected});

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
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.mhxChoosePeriod,
                  style: theme.type.sectionLabel.copyWith(color: surfaces.brand),
                ),
              ),
              const SizedBox(height: 16),
              _PeriodOption(
                label: l10n.mhxPeriod6Months,
                onTap: () => onSelected(ExportPeriod.sixMonths),
              ),
              const SizedBox(height: 10),
              _PeriodOption(
                label: l10n.mhxPeriod1Year,
                recommended: true,
                onTap: () => onSelected(ExportPeriod.oneYear),
              ),
              const SizedBox(height: 10),
              _PeriodOption(
                label: l10n.mhxPeriodAll,
                onTap: () => onSelected(ExportPeriod.all),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  final String label;
  final bool recommended;
  final VoidCallback onTap;

  const _PeriodOption({
    required this.label,
    required this.onTap,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusCard);

    return Material(
      color: recommended ? surfaces.selection : surfaces.inset,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: surfaces.brand),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 15,
                    color: surfaces.brand,
                  ),
                ),
              ),
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: surfaces.inkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
