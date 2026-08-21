import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import 'med_icon.dart';

/// Hoja «Registrar toma»: confirma una toma concreta como tomada u omitida.
/// Registra la transición en el controlador (que descuenta inventario y
/// reprograma los avisos) y cierra la hoja.
Future<void> showRegisterDoseSheet(
  BuildContext context,
  MedicationDayEntry entry,
) {
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
    builder: (_) => _RegisterDoseSheet(entry: entry),
  );
}

class _RegisterDoseSheet extends StatelessWidget {
  const _RegisterDoseSheet({required this.entry});

  final MedicationDayEntry entry;

  Future<void> _log(BuildContext context, {required bool taken}) async {
    final controller = context.read<MedicationsController>();
    final navigator = Navigator.of(context);
    await controller.logDose(entry, taken: taken);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final vm = doseVm(entry, l10n);
    final med = entry.medication;
    final strength = strengthLabel(med);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabber(surfaces.divider),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  l10n.medRegisterDose,
                  style: theme.type.screenTitle.copyWith(fontSize: 24),
                ),
                const Spacer(),
                Text(
                  vm.time,
                  style: theme.type.numeralSmall.copyWith(
                    fontSize: 18,
                    color: surfaces.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: surfaces.cardDecoration(),
              child: Column(
                children: [
                  MedIcon(
                    icon: vm.icon,
                    color: vm.color,
                    size: 64,
                    iconSize: 30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    vm.medName,
                    style: theme.type.screenTitle.copyWith(fontSize: 26),
                  ),
                  if (strength.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${formName(med.form, l10n)} · $strength',
                      style: theme.type.meta,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    l10n.medDoseAtTime(vm.amount, vm.time),
                    style: theme.type.cardTitle.copyWith(fontSize: 18),
                  ),
                  if ((med.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(med.notes!, style: theme.type.meta),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SheetButton(
                    label: l10n.medSkip,
                    solid: false,
                    color: surfaces.brand,
                    onTap: () => _log(context, taken: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _SheetButton(
                    label: l10n.medicationTaken,
                    solid: true,
                    color: surfaces.brand,
                    icon: Icons.check,
                    onTap: () => _log(context, taken: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _grabber(Color color) => Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

/// Botón de acción de las hojas del módulo. Extraído aquí para reutilizarlo en
/// la hoja de varias tomas sin depender del ActionButton (que es de ancho fijo
/// vertical y no admite icono).
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.solid,
    required this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool solid;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);
    final bg = solid ? color : Color.lerp(surfaces.card, color, 0.10)!;
    final fg = solid ? surfaces.onBrand : color;

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: theme.type.button.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reutilizable por otras hojas del módulo.
class MedSheetButton extends StatelessWidget {
  const MedSheetButton({
    super.key,
    required this.label,
    required this.solid,
    required this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool solid;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _SheetButton(
    label: label,
    solid: solid,
    color: color,
    icon: icon,
    onTap: onTap,
  );
}

/// Barra superior con grabber, reutilizable.
Widget medSheetGrabber(BuildContext context) =>
    _grabber(Theme.of(context).surfaces.divider);
