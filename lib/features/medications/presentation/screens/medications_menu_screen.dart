import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/settings_accent.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/medication.dart';
import '../../domain/medication_inventory_service.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../widgets/low_inventory_banner.dart';
import '../widgets/med_icon.dart';
import '../view_models/med_view_models.dart';
import '../widgets/medication_list_row.dart';

/// Menú del módulo Medicamentos, ya dentro de Perfil y conectado a datos reales.
///
/// Adopta el molde de Perfil —[SecondaryAppBar] azul + [SettingsPageHeader] +
/// filas de menú con su tono— y lee del [MedicationsController]: contador de
/// tomas de hoy, aviso de inventario, adherencia del mes y la lista de
/// medicamentos. Cada fila abre su propia subpantalla.
class MedicationsMenuScreen extends StatefulWidget {
  const MedicationsMenuScreen({super.key});

  @override
  State<MedicationsMenuScreen> createState() => _MedicationsMenuScreenState();
}

class _MedicationsMenuScreenState extends State<MedicationsMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Fija los textos localizados de las notificaciones para que la
    // reprogramación de avisos use el idioma activo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<MedicationsController>().setNotificationTextBuilders(
            doseText: (med, dose) => (
              title: l10n.medicationDoseNotifTitle(med.name),
              body: l10n.medicationDoseNotifBody,
            ),
            inventoryText: (med) => (
              title: l10n.medicationRefillNotifTitle(med.name),
              body: l10n.medicationRefillNotifBody,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final meds = controller.activeMedications;
    final entries = controller.entriesForDay(now);
    final pending = entries.where((e) => e.isPending).length;

    // Medicamentos que deberían avisar de recompra hoy.
    final lowMeds = meds
        .where((m) => MedicationInventoryService.shouldAlert(
              m,
              controller.dosesFor(m.id),
              today: now,
            ))
        .toList();

    final adherence = controller.adherence();
    final pct = adherence.monthlyAdherence(now, today: now);
    final streak = adherence.currentStreak(today: now);

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          SecondaryAppBar(title: l10n.medicationsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                SettingsPageHeader(
                  icon: Icons.medication_outlined,
                  title: l10n.medicationsTitle,
                  description: l10n.medMenuDescription,
                  accent: SettingsSection.medications.tone(theme),
                ),
                const SizedBox(height: 28),

                if (meds.isEmpty)
                  const _EmptyState()
                else ...[
                  if (lowMeds.isNotEmpty)
                    _LowBanner(med: lowMeds.first, controller: controller),
                  if (lowMeds.isNotEmpty) const SizedBox(height: 20),

                  _MedMenuTile(
                    icon: Icons.today,
                    title: l10n.medTodayTitle,
                    subtitle: l10n.medMenuTodaySubtitle(pending),
                    tone: theme.content.heart,
                    onTap: () => context.push('/profile/medications/today'),
                  ),
                  _MedMenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.medInventoryTitle,
                    subtitle: l10n.medMenuInventorySubtitle(lowMeds.length),
                    tone: theme.clinical.caution,
                    onTap: () =>
                        context.push('/profile/medications/inventory'),
                  ),
                  _MedMenuTile(
                    icon: Icons.insights,
                    title: l10n.medAdherenceTitle,
                    subtitle: l10n.medMenuAdherenceSubtitle(pct, streak),
                    tone: theme.clinical.optimal,
                    onTap: () =>
                        context.push('/profile/medications/adherence'),
                  ),
                  const SizedBox(height: 28),

                  Text(l10n.medSectionYourMeds, style: theme.type.sectionLabel),
                  const SizedBox(height: 12),
                  for (final m in meds)
                    MedicationListRow(
                      med: medVmForMedication(controller, m, l10n, locale,
                          today: now),
                      onTap: () => context.push(
                        '/profile/medications/detail',
                        extra: m.id,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _AddButton(
                    label: l10n.medicationAdd,
                    onTap: () => context.push('/profile/medications/add'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de inventario bajo para el primer medicamento por agotarse.
class _LowBanner extends StatelessWidget {
  const _LowBanner({required this.med, required this.controller});

  final Medication med;
  final MedicationsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doses = controller.dosesFor(med.id);
    final days = MedicationInventoryService.daysRemaining(med, doses);
    final stock = (med.stockQuantity ?? 0).round();

    return LowInventoryBanner(
      title: l10n.medLowStockBannerTitle(med.name, stock),
      subtitle: days != null ? l10n.medRunsOutInDays(days) : '',
      actionLabel: l10n.medicationRefill,
      onAction: () =>
          context.push('/profile/medications/refill', extra: med.id),
    );
  }
}

/// Fila de menú del módulo, con el mismo aspecto que las filas de Perfil.
class _MedMenuTile extends StatelessWidget {
  const _MedMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Tone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = surfaces.radiusCard;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaces.selection,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tone.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tone.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.type.cardTitle.copyWith(
                        fontSize: 15,
                        color: surfaces.brand,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.type.meta),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: surfaces.brand, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de alta, en el azul de marca, coherente con los CTA de Perfil.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);

    return Material(
      color: surfaces.brand,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: surfaces.onBrand),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.type.button.copyWith(color: surfaces.onBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vacío para cuando aún no hay medicamentos.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const MedIcon(
            icon: Icons.medication,
            color: MedColor.teal,
            size: 88,
            iconSize: 44,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.medEmptyTitle,
            style: theme.type.screenTitle.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.medEmptyBody,
            style: theme.type.body.copyWith(color: surfaces.inkSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _AddButton(
            label: l10n.medicationAdd,
            onTap: () => context.push('/profile/medications/add'),
          ),
        ],
      ),
    );
  }
}
