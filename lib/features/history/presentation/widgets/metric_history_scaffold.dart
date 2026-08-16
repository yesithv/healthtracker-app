import 'package:flutter/material.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/action_button.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_chip_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/period_filter_dropdown.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Esqueleto común de una pantalla de historial de tendencia, genérico sobre el
/// tipo de registro [R] y el tipo de métrica [M].
///
/// Antropometría y signos vitales (y mañana lípidos y composición corporal)
/// comparten exactamente la misma estructura de arriba a abajo: mensaje superior,
/// filtro de periodo, chips que reparten la gráfica entre métricas, la gráfica,
/// los botones de exportación, y la lista de mediciones (deslizar para borrar,
/// tocar para editar) con su paginación «ver más». Antes cada pantalla copiaba
/// ese `build()` entero —junto con el estado de carga/vacío, el diálogo de
/// borrado, el fondo de deslizamiento y los botones de export— carácter a
/// carácter. Aquí vive una sola vez.
///
/// Este widget POSEE el estado de UI que solo mueve el esqueleto: el periodo
/// seleccionado, la métrica seleccionada y cuántos ítems se muestran. Cada
/// llamante aporta únicamente lo que varía por indicador vía los `builder`:
/// el banner ([bannerBuilder]), la gráfica ([chartBuilder]) y la tarjeta de cada
/// medición ([itemBuilder]), más las acciones (editar, borrar, exportar).
class MetricHistoryScaffold<R, M> extends StatefulWidget {
  const MetricHistoryScaffold({
    super.key,
    required this.isLoaded,
    required this.records,
    required this.dateOf,
    required this.idOf,
    required this.family,
    required this.metricChips,
    required this.initialMetric,
    required this.bannerBuilder,
    required this.chartBuilder,
    required this.itemBuilder,
    required this.onEdit,
    required this.onDelete,
    required this.onExportPdf,
    required this.onExportCsv,
    required this.emptyIcon,
    required this.emptyText,
    required this.emptyActionLabel,
    required this.onEmptyAction,
  });

  /// `false` mientras el repositorio carga su caché; muestra un spinner.
  final bool isLoaded;

  /// Lista completa SIN filtrar; el scaffold aplica el filtro de periodo, el
  /// orden y la paginación.
  final List<R> records;

  /// Fecha de un registro (para filtrar por periodo y ordenar).
  final DateTime Function(R) dateOf;

  /// Id de un registro (clave del `Dismissible` y argumento de [onDelete]).
  final String Function(R) idOf;

  /// Identidad de color de la familia del indicador; tiñe la barra de chips.
  final Tone family;

  /// Chips que reparten la gráfica entre métricas. Si hay una sola, la barra se
  /// oculta (no hay nada que elegir).
  final List<MetricChip<M>> metricChips;

  /// Métrica seleccionada al abrir la pantalla.
  final M initialMetric;

  /// Mensaje superior. Recibe los registros del periodo en orden ascendente por
  /// si el subtítulo depende de los datos (p. ej. pérdida de peso).
  final Widget Function(List<R> ascending) bannerBuilder;

  /// Gráfica del indicador para la [metric] elegida. Recibe los registros del
  /// periodo en orden ascendente y el rótulo del periodo ya localizado.
  final Widget Function(M metric, List<R> ascending, String filterLabel)
  chartBuilder;

  /// Tarjeta de una medición (normalmente un `MeasurementHistoryCard`).
  final Widget Function(R record) itemBuilder;

  /// Abre la pantalla de registro para editar [record].
  final void Function(R record) onEdit;

  /// Borra el registro con ese id (solo la llamada al repositorio). El diálogo de
  /// confirmación y el aviso de éxito los pone el propio scaffold.
  final Future<void> Function(String id) onDelete;

  /// Exporta los registros del periodo (en orden más reciente primero, igual que
  /// se ven en la lista). El scaffold pasa la lista ya filtrada.
  final void Function(List<R> records) onExportPdf;
  final void Function(List<R> records) onExportCsv;

  /// Estado vacío (sin registros en el periodo): icono, texto y acción para
  /// registrar la primera medición.
  final IconData emptyIcon;
  final String emptyText;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;

  @override
  State<MetricHistoryScaffold<R, M>> createState() =>
      _MetricHistoryScaffoldState<R, M>();
}

class _MetricHistoryScaffoldState<R, M>
    extends State<MetricHistoryScaffold<R, M>> {
  HistoryPeriod _selectedPeriod = HistoryPeriod.allTime;
  late M _selectedMetric = widget.initialMetric;

  static const int _pageSize = 15;
  int _visibleCount = _pageSize;

  ThemeData get _theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final surfaces = _theme.surfaces;

    final filtered = _selectedPeriod
        .filter<R>(widget.records, widget.dateOf)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.emptyIcon, size: 60, color: surfaces.inkMuted),
              const SizedBox(height: 16),
              Text(
                widget.emptyText,
                textAlign: TextAlign.center,
                style: _theme.type.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ActionButton(
                text: widget.emptyActionLabel,
                color: widget.family.accent,
                solid: true,
                onPressed: widget.onEmptyAction,
              ),
            ],
          ),
        ),
      );
    }

    // Orden ascendente (más antiguo primero) para gráfica y export; invertido
    // para la lista (más reciente arriba).
    final ascending = List<R>.from(filtered)
      ..sort((a, b) => widget.dateOf(a).compareTo(widget.dateOf(b)));
    final reversed = ascending.reversed.toList();

    final String filterLabel = _selectedPeriod.label(l10n);

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        widget.bannerBuilder(ascending),
        const SizedBox(height: 16),

        // Filtro de periodo de la gráfica.
        PeriodFilterDropdown(
          value: _selectedPeriod,
          onChanged: (p) => setState(() {
            _selectedPeriod = p;
            _visibleCount = _pageSize;
          }),
        ),
        const SizedBox(height: 12),

        // Selector de métrica: reparte la gráfica entre las series del indicador.
        // Con una sola métrica no hay nada que elegir, así que se oculta.
        if (widget.metricChips.length > 1) ...[
          MetricChipBar<M>(
            items: widget.metricChips,
            selected: _selectedMetric,
            onSelected: (m) => setState(() => _selectedMetric = m),
            family: widget.family,
          ),
          const SizedBox(height: 16),
        ],

        widget.chartBuilder(_selectedMetric, ascending, filterLabel),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _exportButton(
                Icons.picture_as_pdf,
                l10n.historyExportPdf,
                Colors.red[600]!,
                () => widget.onExportPdf(reversed),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _exportButton(
                Icons.table_chart,
                l10n.historyExportCsv,
                Colors.green[700]!,
                () => widget.onExportCsv(reversed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          l10n.historyMeasurements,
          style: _theme.type.sectionLabel.copyWith(
            color: surfaces.inkSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...reversed
            .take(_visibleCount)
            .map(
              (r) => Dismissible(
                key: ValueKey(widget.idOf(r)),
                direction: DismissDirection.endToStart,
                background: _deleteSwipeBackground(),
                confirmDismiss: (_) => _confirmDelete(l10n, widget.idOf(r)),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onEdit(r),
                  child: widget.itemBuilder(r),
                ),
              ),
            ),
        if (reversed.length > _visibleCount)
          _buildShowMoreButton(reversed.length, l10n),
        const SizedBox(height: 40),
      ],
    );
  }

  /// "Show N more" button that reveals the next page of history items. The full
  /// list stays in memory for charts/filters/export; this only caps how many
  /// item widgets are built at once.
  Widget _buildShowMoreButton(int total, AppLocalizations l10n) {
    final remaining = total - _visibleCount;
    final surfaces = _theme.surfaces;
    return Center(
      child: TextButton.icon(
        onPressed: () => setState(() => _visibleCount += _pageSize),
        icon: Icon(Icons.expand_more, size: 18, color: surfaces.brand),
        label: Text(
          l10n.historyShowMore(remaining),
          style: _theme.type.button.copyWith(color: surfaces.brand),
        ),
      ),
    );
  }

  Widget _exportButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    return Material(
      color: surfaces.card,
      borderRadius: BorderRadius.circular(surfaces.radiusCard),
      // Los temas planos no elevan los controles.
      elevation: surfaces.cardShadow.isEmpty ? 0 : 3,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(surfaces.radiusCard),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.02),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.type.button.copyWith(
                    color: color,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Red background revealed when swiping a history item left to delete it.
  Widget _deleteSwipeBackground() {
    final surfaces = _theme.surfaces;
    final danger = _theme.clinical.alert;
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: danger.accent,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
      ),
      child: Icon(Icons.delete_outline, color: danger.onAccent),
    );
  }

  /// Asks the user to confirm deletion, then deletes the record. Always returns
  /// false so the [Dismissible] never self-removes: the repository listener
  /// re-fetches the list and drops the row, which is what updates the UI.
  Future<bool> _confirmDelete(AppLocalizations l10n, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final surfaces = theme.surfaces;
    final danger = theme.clinical.alert;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
        ),
        title: Text(l10n.deleteRecordTitle, style: theme.type.cardTitle),
        content: Text(l10n.deleteRecordBody, style: theme.type.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: theme.type.button.copyWith(color: surfaces.inkSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.deleteRecordConfirm,
              // Borrar es la acción destructiva: va en el rojo de ALERTA, el
              // mismo que un valor fuera de rango. Aquí también significa
              // «esto no se deshace».
              style: theme.type.button.copyWith(color: danger.accent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onDelete(id);
      final ok = theme.clinical.optimal;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.recordDeleted,
            style: theme.type.body.copyWith(color: ok.onAccent),
          ),
          backgroundColor: ok.accent,
        ),
      );
    }
    return false;
  }
}
