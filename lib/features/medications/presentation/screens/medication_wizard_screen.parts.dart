part of 'medication_wizard_screen.dart';

// Piezas presentacionales del asistente de medicamentos. Viven en la MISMA
// librería que `medication_wizard_screen.dart` (por eso el `part of`): son
// privadas del asistente, no se usan fuera, y separarlas sólo aligera el
// archivo principal, que se queda con el estado y los cinco pasos.

// ─────────────────────────────────────── Piezas del asistente

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).type.sectionLabel),
      );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.type.body,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: surfaces.inset,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: surfaces.inset,
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.type.body)),
            Icon(Icons.calendar_today, size: 18, color: surfaces.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap(
      {required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _Chip(
              label: options[i],
              selected: selected == i,
              onTap: () => onSelect(i)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: selected ? surfaces.brand : surfaces.inset,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: theme.type.button.copyWith(
              fontSize: 15,
              color: selected ? surfaces.onBrand : surfaces.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});
  final MedColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final tone = resolveMedTone(context, color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tone.accent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: surfaces.ink, width: 2) : null,
        ),
      ),
    );
  }
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: selected ? surfaces.selection : Colors.transparent,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(
                color: selected ? surfaces.brand : surfaces.divider),
          ),
          child: Text(
            label,
            style: theme.type.button.copyWith(
              fontSize: 14,
              color: selected ? surfaces.ink : surfaces.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(
      {required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == i ? surfaces.brand : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(surfaces.radiusControl - 2),
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: theme.type.button.copyWith(
                      fontSize: 13,
                      color:
                          selected == i ? surfaces.onBrand : surfaces.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? surfaces.brand : surfaces.inset,
        ),
        child: Text(
          label,
          style: theme.type.button.copyWith(
            color: selected ? surfaces.onBrand : surfaces.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.time, required this.onEdit, this.onRemove});
  final TimeOfDay time;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final label = timeLabelHM(time.hour, time.minute);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surfaces.inset,
              borderRadius: BorderRadius.circular(surfaces.radiusIcon),
            ),
            child: Icon(Icons.schedule, size: 18, color: surfaces.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Text(label,
                  style: theme.type.numeral.copyWith(fontSize: 22)),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 18, color: surfaces.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.type.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.type.meta),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: surfaces.onBrand,
            activeTrackColor: surfaces.brand,
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: surfaces.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.type.cardTitle.copyWith(fontSize: 16)),
          ),
          _MiniStepper(value: value, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper(
      {required this.value, required this.onMinus, required this.onPlus});
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    Widget btn(IconData icon, VoidCallback onTap) => Material(
          color: surfaces.inset,
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(icon, size: 18, color: surfaces.brand)),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove, onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value',
              style: theme.type.numeral.copyWith(fontSize: 22)),
        ),
        btn(Icons.add, onPlus),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

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
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text(label,
              style: theme.type.button.copyWith(color: surfaces.onBrand)),
        ),
      ),
    );
  }
}
