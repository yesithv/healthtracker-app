import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/ranges/chart_bands.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/action_button.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';

class BodyCompositionHistoryTab extends StatefulWidget {
  const BodyCompositionHistoryTab({super.key});

  @override
  State<BodyCompositionHistoryTab> createState() =>
      _BodyCompositionHistoryTabState();
}

class _BodyCompositionHistoryTabState extends State<BodyCompositionHistoryTab> {
  String _selectedFilter = 'all';

  static const int _pageSize = 15;
  int _visibleCount = _pageSize;

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «composición corporal»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.bodyComposition);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<BodyCompositionRepository>();
    if (!repo.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final surfaces = _theme.surfaces;

    final recordsListTemp = repo.items;

    final now = DateTime.now();
    List<BodyCompositionRecord> filteredRecords = recordsListTemp;
    if (_selectedFilter == '7days') {
      filteredRecords = recordsListTemp
          .where((r) => now.difference(r.date).inDays <= 7)
          .toList();
    } else if (_selectedFilter == '30days') {
      filteredRecords = recordsListTemp
          .where((r) => now.difference(r.date).inDays <= 30)
          .toList();
    } else if (_selectedFilter == '6months') {
      filteredRecords = recordsListTemp
          .where((r) => now.difference(r.date).inDays <= 180)
          .toList();
    }

    if (filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.accessibility_new, size: 60, color: surfaces.inkMuted),
              const SizedBox(height: 16),
              Text(
                l10n.noDataYet,
                textAlign: TextAlign.center,
                style: _theme.type.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ActionButton(
                text: l10n.completeBodyProfile,
                color: _family.accent,
                solid: true,
                onPressed: () => context.push('/record-body-composition'),
              ),
            ],
          ),
        ),
      );
    }

    final recordsList = List<BodyCompositionRecord>.from(filteredRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

    final reversedRecords = recordsList.reversed.toList();

    String bannerSubtitle = l10n.historyGoalProgress;

    String filterLabel = l10n.filterAllTime;
    if (_selectedFilter == '7days') filterLabel = l10n.filterLast7Days;
    if (_selectedFilter == '30days') filterLabel = l10n.filterLast30Days;
    if (_selectedFilter == '6months') filterLabel = l10n.filterLast6Months;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        _buildGoodJobBanner(l10n, bannerSubtitle),
        const SizedBox(height: 16),

        // Filter Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButton<String>(
              value: _selectedFilter,
              icon: Icon(
                Icons.filter_list,
                size: 18,
                color: surfaces.inkSecondary,
              ),
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              borderRadius: BorderRadius.circular(surfaces.radiusControl),
              dropdownColor: surfaces.card,
              style: _theme.type.button.copyWith(
                fontSize: 13,
                color: surfaces.inkSecondary,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilter = newValue;
                    _visibleCount = _pageSize;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: '7days',
                  child: Text(l10n.filterLast7Days),
                ),
                DropdownMenuItem(
                  value: '30days',
                  child: Text(l10n.filterLast30Days),
                ),
                DropdownMenuItem(
                  value: '6months',
                  child: Text(l10n.filterLast6Months),
                ),
                DropdownMenuItem(value: 'all', child: Text(l10n.filterAllTime)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildChartContainer(l10n, recordsList, filterLabel),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildExportButton(
                Icons.picture_as_pdf,
                l10n.historyExportPdf,
                Colors.red[600]!,
                () => _exportPdf(reversedRecords, l10n),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildExportButton(
                Icons.table_chart,
                l10n.historyExportCsv,
                Colors.green[700]!,
                () => _exportCsv(reversedRecords, l10n),
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
        ...reversedRecords
            .take(_visibleCount)
            .map(
              (r) => Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: _deleteSwipeBackground(),
                confirmDismiss: (_) => _confirmDelete(l10n, r.id),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      context.push('/record-body-composition', extra: r),
                  child: _buildHistoryItem(r, l10n),
                ),
              ),
            ),
        if (reversedRecords.length > _visibleCount)
          _buildShowMoreButton(reversedRecords.length, l10n),
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

  Widget _buildGoodJobBanner(AppLocalizations l10n, String text) {
    final theme = _theme;
    // El aviso va del color de la FAMILIA, no de la paleta clínica: no
    // afirma nada sobre la salud del usuario, solo dice de qué indicador
    // habla. Eran cinco tonos a mano; ahora salen los tres del mismo tono.
    final family = _family;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: family.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: family.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: family.accent.withValues(alpha: 0.15),
            radius: 16,
            child: Icon(
              Icons.accessibility_new,
              color: family.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyGoodJob,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 16,
                    color: family.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.type.body.copyWith(
                    fontSize: 13,
                    color: family.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    AppLocalizations l10n,
    List<BodyCompositionRecord> records,
    String filterLabel,
  ) {
    final surfaces = _theme.surfaces;
    final family = _family;
    // We only plot records that have Body Fat
    final validRecords = records
        .where((r) => r.bodyFatPercent != null)
        .toList();
    if (validRecords.isEmpty) return const SizedBox.shrink();

    // Muestreo uniforme de toda la serie filtrada (conserva primero y último), en
    // vez del viejo `sublist(length - 6)` que ignoraba el filtro.
    final recentRecords = downsample(validRecords);
    final axisFmt = axisDateFormat(
      recentRecords.first.date,
      recentRecords.last.date,
    );
    final labelStep = axisLabelStep(recentRecords.length);
    final List<FlSpot> spotsFat = [];
    double minV = recentRecords.first.bodyFatPercent!;
    double maxV = recentRecords.first.bodyFatPercent!;

    for (int i = 0; i < recentRecords.length; i++) {
      double v = recentRecords[i].bodyFatPercent!;
      spotsFat.add(FlSpot(i.toDouble(), v));
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    double minDisplay = math.min(minV - 5, 0.0);
    double maxDisplay = math.max(maxV + 5, 40.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.compositionBodyFat.toUpperCase(),
                style: _theme.type.sectionLabel.copyWith(
                  fontSize: 11,
                  color: surfaces.inkSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: surfaces.inset,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filterLabel,
                  style: _theme.type.badge.copyWith(
                    fontSize: 10,
                    color: surfaces.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minDisplay,
                maxY: maxDisplay,
                // Zonas de referencia del paciente (su báscula/sexo/edad, desde el
                // servidor): la gráfica se pinta como el CRM la ve en "Vista del paciente".
                rangeAnnotations: bandRangeAnnotations(
                  'BODY_FAT',
                  palette: _theme.clinical,
                  minY: minDisplay,
                  maxY: maxDisplay,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: surfaces.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final isLast = index == recentRecords.length - 1;
                        if (index >= 0 &&
                            index < recentRecords.length &&
                            (index % labelStep == 0 || isLast)) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              axisFmt.format(recentRecords[index].date),
                              style: _theme.type.numeralUnit.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: _theme.type.numeralUnit.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsFat,
                    isCurved: true,
                    color: family.accent,
                    barWidth: surfaces.chartLineWidth,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 4,
                        color: family.accent,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
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

  Future<void> _exportPdf(
    List<BodyCompositionRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final pdf = pw.Document();

    final List<List<String>> tableData = [
      [
        l10n.historyColDate,
        l10n.exportColBodyFat,
        l10n.exportColMuscleMass,
        l10n.exportColVisceralFat,
      ],
      ...records.map((r) {
        return [
          DateFormat('dd MMM yyyy').format(r.date),
          r.bodyFatPercent != null ? '${r.bodyFatPercent}%' : '-',
          r.muscleMassKg != null ? '${r.muscleMassKg}kg' : '-',
          r.visceralFatLevel?.toString() ?? '-',
        ];
      }),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                l10n.compositionPdfTitle,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: tableData.first,
              data: tableData.sublist(1),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.orange800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200),
                ),
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    try {
      final ok = await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'body_composition_history.pdf',
      );
      showShareFeedback(
        messenger,
        theme,
        l10n,
        ok ? ShareOutcome.success : ShareOutcome.silent,
      );
    } catch (_) {
      showShareFeedback(messenger, theme, l10n, ShareOutcome.error);
    }
  }

  Future<void> _exportCsv(
    List<BodyCompositionRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    List<List<dynamic>> rows = [
      [
        l10n.historyColDate,
        '${l10n.exportColBodyFat} %',
        '${l10n.exportColMuscleMass} kg',
        l10n.exportColVisceralFat,
        l10n.exportColMetabolicAge,
        '${l10n.exportColBodyWater} %',
        '${l10n.exportColBoneMass} kg',
        '${l10n.exportColBmr} kcal',
        l10n.exportColComment,
      ],
      ...records.map((r) {
        return [
          DateFormat('dd/MM/yyyy HH:mm').format(r.date),
          r.bodyFatPercent ?? '',
          r.muscleMassKg ?? '',
          r.visceralFatLevel ?? '',
          r.metabolicAge ?? '',
          r.bodyWaterPercent ?? '',
          r.boneMassKg ?? '',
          r.bmrKcal ?? '',
          r.comment ?? '',
        ];
      }),
    ];
    String csvData = csv.encode(rows);
    final bytes = utf8.encode(csvData);
    final outcome = await runShare(
      () => SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: 'body_composition_history.csv',
              mimeType: 'text/csv',
            ),
          ],
          subject: l10n.compositionShareCsvSubject,
        ),
      ),
    );
    showShareFeedback(messenger, theme, l10n, outcome);
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
      await BodyCompositionRepository.instance.delete(id);
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

  /// Línea compacta con los demás valores del registro (músculo %/kg, visceral,
  /// edad metabólica, TMB) — visible p. ej. en la historia importada del legacy.
  String? _secondaryLine(BodyCompositionRecord r, AppLocalizations l10n) {
    final parts = <String>[
      if (r.musclePct != null)
        '${l10n.dashboardCompositionMuscle} ${r.musclePct}%',
      if (r.musclePct == null && r.muscleMassKg != null)
        '${l10n.dashboardCompositionMuscle} ${r.muscleMassKg}kg',
      if (r.visceralFatLevel != null)
        '${l10n.dashboardCompositionVisceral} ${r.visceralFatLevel}',
      if (r.metabolicAge != null)
        '${l10n.compositionMetabolicAge} ${r.metabolicAge}',
      if (r.bmrKcal != null) '${r.bmrKcal} kcal',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _buildHistoryItem(
    BodyCompositionRecord record,
    AppLocalizations l10n,
  ) {
    final theme = _theme;
    final surfaces = theme.surfaces;
    final double defaultFat = record.bodyFatPercent ?? 0.0;
    final FatCategory fatCat = FatCategory.of(defaultFat);
    final String statusLabel = fatCat.label(l10n);
    final dateFormat = DateFormat(
      'dd MMM yyyy',
    ).format(record.date).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: surfaces.cardDecoration().copyWith(
        border: Border.all(color: surfaces.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat,
                style: theme.type.sectionLabel.copyWith(
                  fontSize: 10,
                  color: surfaces.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.bodyFatPercent != null
                        ? '${record.bodyFatPercent}'
                        : 'N/A',
                    style: theme.type.numeralSmall.copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '% ${l10n.dashboardCompositionFat}',
                    style: theme.type.numeralUnit.copyWith(fontSize: 11),
                  ),
                ],
              ),
              if (_secondaryLine(record, l10n) != null) ...[
                const SizedBox(height: 4),
                Text(
                  _secondaryLine(record, l10n)!,
                  style: theme.type.meta.copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
          // Era una insignia calcada a mano con el color de FÁBRICA del
          // clasificador (`fatCat.color`), que ignoraba el tema y además
          // siempre se dibujaba suave. StatusChip pide el ESTADO y deja que el
          // tema resuelva el acabado. Mismo texto, misma condición, mismo sitio.
          if (record.bodyFatPercent != null)
            StatusChip(
              status: fatCat.status,
              label: statusLabel,
              icon: iconForStatus(fatCat.status),
            ),
        ],
      ),
    );
  }
}
