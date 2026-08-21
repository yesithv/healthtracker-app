import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../view_models/med_view_models.dart';
import 'med_icon.dart';
import 'register_dose_sheet.dart';

/// Hoja «N tomas a las HH:MM»: varias tomas que coinciden a la misma hora. Cada
/// fila se marca como tomada; «Registrar N» guarda las marcadas como tomadas y
/// «Omitir resto» marca como omitidas las no marcadas. Todo pasa por el
/// controlador (inventario + reprogramación).
Future<void> showRegisterMultipleSheet(
  BuildContext context,
  List<MedicationDayEntry> entries,
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
    builder: (_) => _RegisterMultipleSheet(entries: entries),
  );
}

class _RegisterMultipleSheet extends StatefulWidget {
  const _RegisterMultipleSheet({required this.entries});

  final List<MedicationDayEntry> entries;

  @override
  State<_RegisterMultipleSheet> createState() => _RegisterMultipleSheetState();
}

class _RegisterMultipleSheetState extends State<_RegisterMultipleSheet> {
  /// Índices marcados como tomados. Por defecto, todas las pendientes marcadas.
  late final Set<int> _selected = {
    for (var i = 0; i < widget.entries.length; i++)
      if (!widget.entries[i].isSkipped) i,
  };

  String get _time {
    final e = widget.entries.first;
    return timeLabelHM(e.scheduledAt.hour, e.scheduledAt.minute);
  }

  Future<void> _registerSelected() async {
    final controller = context.read<MedicationsController>();
    final navigator = Navigator.of(context);
    final selected = [
      for (var i = 0; i < widget.entries.length; i++)
        if (_selected.contains(i)) widget.entries[i],
    ];
    // Registro en lote: reprograma los avisos una sola vez (no una por toma).
    await controller.logDoses(selected, taken: true);
    navigator.pop();
  }

  Future<void> _skipRest() async {
    final controller = context.read<MedicationsController>();
    final navigator = Navigator.of(context);
    final rest = [
      for (var i = 0; i < widget.entries.length; i++)
        if (!_selected.contains(i)) widget.entries[i],
    ];
    await controller.logDoses(rest, taken: false);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            medSheetGrabber(context),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.medMultipleTitle(widget.entries.length, _time),
                        style: theme.type.screenTitle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.medMultipleSubtitle, style: theme.type.meta),
                    ],
                  ),
                ),
                Text(
                  _time,
                  style: theme.type.numeralSmall.copyWith(
                    fontSize: 18,
                    color: surfaces.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < widget.entries.length; i++)
              _MultiRow(
                vm: doseVm(widget.entries[i], l10n),
                checked: _selected.contains(i),
                onTap: () => setState(() {
                  _selected.contains(i)
                      ? _selected.remove(i)
                      : _selected.add(i);
                }),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MedSheetButton(
                    label: l10n.medSkipRest,
                    solid: false,
                    color: surfaces.brand,
                    onTap: _skipRest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: MedSheetButton(
                    label: l10n.medRegisterNSelected(_selected.length),
                    solid: true,
                    color: surfaces.brand,
                    onTap: _selected.isEmpty ? null : _registerSelected,
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

class _MultiRow extends StatelessWidget {
  const _MultiRow({
    required this.vm,
    required this.checked,
    required this.onTap,
  });

  final DoseVm vm;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: surfaces.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                MedIcon(icon: vm.icon, color: vm.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vm.medName, style: theme.type.cardTitle),
                      const SizedBox(height: 2),
                      Text(vm.amount, style: theme.type.meta),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? surfaces.brand : Colors.transparent,
                    border: checked
                        ? null
                        : Border.all(color: surfaces.divider, width: 2),
                  ),
                  child: checked
                      ? Icon(Icons.check, size: 18, color: surfaces.onBrand)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
