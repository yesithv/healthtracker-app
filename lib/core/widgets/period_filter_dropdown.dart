import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../../l10n/generated/app_localizations.dart';

/// Periodos que cubre el filtro de un historial. El valor viaja como esta enum
/// —no como cadenas sueltas «7days»/«all» repartidas por cada pantalla— para que
/// añadir o quitar un tramo se haga en un solo sitio.
enum HistoryPeriod {
  last7Days,
  last30Days,
  last6Months,
  allTime;

  /// Rótulo ya localizado del tramo.
  String label(AppLocalizations l10n) => switch (this) {
    HistoryPeriod.last7Days => l10n.filterLast7Days,
    HistoryPeriod.last30Days => l10n.filterLast30Days,
    HistoryPeriod.last6Months => l10n.filterLast6Months,
    HistoryPeriod.allTime => l10n.filterAllTime,
  };

  /// Ventana en días del tramo; `null` en «siempre» (sin recorte).
  int? get days => switch (this) {
    HistoryPeriod.last7Days => 7,
    HistoryPeriod.last30Days => 30,
    HistoryPeriod.last6Months => 180,
    HistoryPeriod.allTime => null,
  };

  /// Filtra por fecha con [dateOf], conservando todo si el tramo es «siempre».
  Iterable<R> filter<R>(Iterable<R> records, DateTime Function(R) dateOf) {
    final window = days;
    if (window == null) return records;
    final now = DateTime.now();
    return records.where((r) => now.difference(dateOf(r)).inDays <= window);
  }
}

/// Selector de periodo de un historial (7 días · 30 días · 6 meses · siempre).
///
/// Era el mismo `DropdownButton` copiado carácter a carácter en los cuatro
/// historiales. Extraído aquí para que el filtro se vea y se comporte igual en
/// todos y para que un módulo nuevo lo tenga con una línea.
class PeriodFilterDropdown extends StatelessWidget {
  const PeriodFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HistoryPeriod value;
  final ValueChanged<HistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerRight,
      child: DropdownButton<HistoryPeriod>(
        value: value,
        icon: Icon(Icons.filter_list, size: 20, color: surfaces.inkSecondary),
        underline: const SizedBox(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        dropdownColor: surfaces.card,
        style: theme.type.button.copyWith(
          fontSize: 14,
          color: surfaces.inkSecondary,
        ),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: [
          for (final p in HistoryPeriod.values)
            DropdownMenuItem(value: p, child: Text(p.label(l10n))),
        ],
      ),
    );
  }
}
