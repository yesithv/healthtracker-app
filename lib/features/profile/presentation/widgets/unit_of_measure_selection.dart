import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'profile_settings_layout.dart';

class UnitOfMeasureSelection extends StatefulWidget {
  final MeasurementUnit initialUnit;
  final ValueChanged<MeasurementUnit> onUnitChanged;
  final VoidCallback onConfirm;
  final bool showConfirmButton;

  const UnitOfMeasureSelection({
    super.key,
    this.initialUnit = MeasurementUnit.metric,
    required this.onUnitChanged,
    required this.onConfirm,
    this.showConfirmButton = true,
  });

  @override
  State<UnitOfMeasureSelection> createState() => _UnitOfMeasureSelectionState();
}

class _UnitOfMeasureSelectionState extends State<UnitOfMeasureSelection> {
  late MeasurementUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSettingsLayout(
      icon: Icons.straighten_rounded,
      title: l10n.unitOfMeasureTitle,
      description: l10n.unitOfMeasureDescription,
      showConfirmButton: widget.showConfirmButton,
      onConfirm: widget.onConfirm,
      child: Column(
        children: [
          // Metric Option
          _SelectionCard(
            title: l10n.metricOption,
            subtitle: l10n.metricSubtitle,
            isSelected: _selectedUnit == MeasurementUnit.metric,
            onTap: () {
              setState(() => _selectedUnit = MeasurementUnit.metric);
              widget.onUnitChanged(MeasurementUnit.metric);
            },
          ),
          const SizedBox(height: 16),
          // Imperial Option
          _SelectionCard(
            title: l10n.imperialOption,
            subtitle: l10n.imperialSubtitle,
            isSelected: _selectedUnit == MeasurementUnit.imperial,
            onTap: () {
              setState(() => _selectedUnit = MeasurementUnit.imperial);
              widget.onUnitChanged(MeasurementUnit.imperial);
            },
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaces.card,
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? surfaces.brand : surfaces.divider,
            width: 2,
          ),
          boxShadow: surfaces.cardShadow,
        ),
        child: Row(
          children: [
            // Custom Radio Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? surfaces.brand : surfaces.inkMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: surfaces.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.type.numeralSmall.copyWith(
                      fontSize: 16,
                      color: isSelected ? surfaces.brand : surfaces.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Las unidades («kg · cm · mg/dL») son el caso de uso exacto
                  // de la monoespaciada de etiquetas en «Consulta Serena».
                  Text(subtitle, style: theme.type.fieldLabel),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: surfaces.brand, size: 24),
          ],
        ),
      ),
    );
  }
}
