import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/app_theme.dart';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
