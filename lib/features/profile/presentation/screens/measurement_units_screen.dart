import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import '../widgets/unit_of_measure_selection.dart';

class MeasurementUnitsScreen extends StatefulWidget {
  /// When set, called instead of Navigator.pop() on confirm.
  /// Used by the onboarding wizard to advance to the next step.
  final VoidCallback? onNext;

  /// Whether to show the SecondaryAppBar. Defaults to true (Profile mode).
  final bool showAppBar;

  const MeasurementUnitsScreen({
    super.key,
    this.onNext,
    this.showAppBar = true,
  });

  @override
  State<MeasurementUnitsScreen> createState() => _MeasurementUnitsScreenState();
}

class _MeasurementUnitsScreenState extends State<MeasurementUnitsScreen> {
  MeasurementUnit? _tempUnit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = Provider.of<LocaleUnitsProvider>(context, listen: false);
      setState(() {
        _tempUnit = prefs.unit;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<LocaleUnitsProvider>(context, listen: false);

    final content = SingleChildScrollView(
      child: _tempUnit == null
          ? const Center(child: CircularProgressIndicator())
          : UnitOfMeasureSelection(
              initialUnit: _tempUnit!,
              showConfirmButton: widget.showAppBar,
              onUnitChanged: (unit) {
                setState(() => _tempUnit = unit);
                prefs.setUnit(unit);
              },
              onConfirm: () {
                prefs.setUnit(_tempUnit!);
                if (widget.onNext != null) {
                  widget.onNext!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).surfaces.canvas,
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(child: content),
        ],
      ),
    );
  }
}
