import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/status_chip.dart';
import 'package:myvitals_healthtracker_app/core/widgets/measurement_history_card.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_chip_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_highlight_banner.dart';
import 'package:myvitals_healthtracker_app/core/widgets/period_filter_dropdown.dart';
import 'package:myvitals_healthtracker_app/core/ranges/chart_bands.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/action_button.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Indicadores numéricos que la gráfica del historial de signos vitales puede
/// dibujar. La presión arterial es una serie DOBLE (sistólica + diastólica); la
/// frecuencia cardíaca es una serie ÚNICA con banda de referencia 60–100 bpm.
enum VitalMetric { bloodPressure, heartRate }

class VitalSignsHistoryTab extends StatefulWidget {
  const VitalSignsHistoryTab({super.key});

  @override
  State<VitalSignsHistoryTab> createState() => _VitalSignsHistoryTabState();
}

class _VitalSignsHistoryTabState extends State<VitalSignsHistoryTab> {
  HistoryPeriod _selectedPeriod = HistoryPeriod.allTime;
  VitalMetric _selectedMetric = VitalMetric.bloodPressure;

  static const int _pageSize = 15;
  int _visibleCount = _pageSize;

  // ── Tokens ────────────────────────────────────────────────────────────────

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «signos vitales»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.vitals);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<VitalSignsRepository>();
    if (!repo.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final surfaces = _theme.surfaces;

    final recordsListTemp = repo.items;

    final filteredRecords = _selectedPeriod
        .filter<VitalSignRecord>(recordsListTemp, (r) => r.date)
        .toList();

    if (filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 60, color: surfaces.inkMuted),
              const SizedBox(height: 16),
              Text(
                l10n.noDataYet,
                textAlign: TextAlign.center,
                style: _theme.type.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ActionButton(
                text: l10n.recordVitalsAction,
                color: _family.accent,
                solid: true,
                onPressed: () => context.push('/record-vital-signs'),
              ),
            ],
          ),
        ),
      );
    }

    final recordsList = List<VitalSignRecord>.from(filteredRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

    final reversedRecords = recordsList.reversed.toList();

    String bannerSubtitle = l10n.historyGoalProgress;

    final String filterLabel = _selectedPeriod.label(l10n);

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Mensaje superior: encabeza el indicador con el color de su FAMILIA;
        // no afirma nada sobre la salud, solo dice de qué habla el panel.
        MetricHighlightBanner(
          tone: _family,
          icon: Icons.favorite,
          title: l10n.historyGoodJob,
          subtitle: bannerSubtitle,
        ),
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

        // Selector de indicador: reparte la misma gráfica entre presión arterial
        // (dos series) y frecuencia cardíaca (una serie). Mismo gesto que el
        // historial de antropometría, con la identidad de color de «vitals».
        MetricChipBar<VitalMetric>(
          items: [
            MetricChip(
              value: VitalMetric.bloodPressure,
              label: l10n.vitalMetricBpShort,
            ),
            MetricChip(
              value: VitalMetric.heartRate,
              label: l10n.vitalMetricHrShort,
            ),
          ],
          selected: _selectedMetric,
          onSelected: (m) => setState(() => _selectedMetric = m),
          family: _family,
        ),
        const SizedBox(height: 16),

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
                  onTap: () => context.push('/record-vital-signs', extra: r),
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

  /// Despacha la gráfica según el indicador elegido en la barra de chips.
  Widget _buildChartContainer(
    AppLocalizations l10n,
    List<VitalSignRecord> records,
    String filterLabel,
  ) {
    if (records.isEmpty) return const SizedBox.shrink();
    switch (_selectedMetric) {
      case VitalMetric.bloodPressure:
        return _buildBloodPressureChart(l10n, records, filterLabel);
      case VitalMetric.heartRate:
        return _buildHeartRateChart(l10n, records, filterLabel);
    }
  }

  /// Contenedor común a ambas gráficas: título del indicador, insignia del
  /// periodo, la gráfica (alto fijo) y su leyenda. Solo cambian [title], [chart]
  /// y [legend]; el andamiaje se comparte.
  Widget _chartCard({
    required String title,
    required String filterLabel,
    required Widget chart,
    required Widget legend,
  }) {
    final surfaces = _theme.surfaces;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: _theme.type.sectionLabel.copyWith(
                    fontSize: 11,
                    color: surfaces.inkSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          SizedBox(height: 180, child: chart),
          const SizedBox(height: 16),
          legend,
        ],
      ),
    );
  }

  /// Rejilla horizontal común a las gráficas (sin líneas verticales).
  FlGridData _gridData() => FlGridData(
    show: true,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (value) =>
        FlLine(color: _theme.surfaces.divider, strokeWidth: 1),
  );

  /// Ejes comunes: fechas muestreadas abajo (una etiqueta cada [labelStep] más
  /// la última) y el valor numérico a la izquierda con paso [leftInterval].
  FlTitlesData _axisTitles(
    List<VitalSignRecord> recentRecords,
    DateFormat axisFmt,
    int labelStep,
    double leftInterval,
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            final isLast = index == recentRecords.length - 1;
            // Solo una etiqueta cada `labelStep` (más la última) para no
            // amontonarlas cuando hay muchos puntos.
            if (index >= 0 &&
                index < recentRecords.length &&
                (index % labelStep == 0 || isLast)) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  axisFmt.format(recentRecords[index].date),
                  style: _theme.type.numeralUnit.copyWith(fontSize: 10),
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
          interval: leftInterval,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: _theme.type.numeralUnit.copyWith(fontSize: 10),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// Serie de línea con puntos, del color dado.
  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: _theme.surfaces.chartLineWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (s, p, b, i) =>
            FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0),
      ),
    );
  }

  /// Presión arterial: dos series (sistólica + diastólica) en la misma gráfica.
  Widget _buildBloodPressureChart(
    AppLocalizations l10n,
    List<VitalSignRecord> records,
    String filterLabel,
  ) {
    final family = _family;
    // La sistólica lleva el acento de la familia; la diastólica, el tono FRÍO
    // (`info`), que el contrato semántico garantiza separado en matiz de los
    // cálidos y con 3:1 contra la tarjeta en todos los temas.
    final cool = _theme.clinical.info.accent;

    // Muestreo uniforme de TODA la lista filtrada (conserva primero y último).
    final recentRecords = downsample(records);
    final axisFmt = axisDateFormat(
      recentRecords.first.date,
      recentRecords.last.date,
    );
    final labelStep = axisLabelStep(recentRecords.length);
    final List<FlSpot> spotsSys = [];
    final List<FlSpot> spotsDia = [];
    double minV = recentRecords.first.diastolic.toDouble();
    double maxV = recentRecords.first.systolic.toDouble();

    for (int i = 0; i < recentRecords.length; i++) {
      final s = recentRecords[i].systolic.toDouble();
      final d = recentRecords[i].diastolic.toDouble();
      spotsSys.add(FlSpot(i.toDouble(), s));
      spotsDia.add(FlSpot(i.toDouble(), d));
      if (d < minV) minV = d;
      if (s > maxV) maxV = s;
    }

    final double minDisplay = math.min(minV - 10, 50.0);
    final double maxDisplay = math.max(maxV + 10, 150.0);

    return _chartCard(
      title: l10n.bloodPressureTitle.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          gridData: _gridData(),
          titlesData: _axisTitles(recentRecords, axisFmt, labelStep, 20),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _lineBar(spotsSys, family.accent),
            _lineBar(spotsDia, cool),
          ],
        ),
      ),
      legend: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 12, height: 2, color: family.accent),
          const SizedBox(width: 4),
          Text(
            l10n.systolicLabel,
            style: _theme.type.meta.copyWith(fontSize: 10),
          ),
          const SizedBox(width: 16),
          Container(width: 12, height: 2, color: cool),
          const SizedBox(width: 4),
          Text(
            l10n.diastolicLabel,
            style: _theme.type.meta.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Frecuencia cardíaca: una sola serie con la banda de referencia saludable
  /// (zonas del servidor `HEART_RATE`; fallback offline 60–100 bpm).
  Widget _buildHeartRateChart(
    AppLocalizations l10n,
    List<VitalSignRecord> records,
    String filterLabel,
  ) {
    final family = _family;
    final clinical = _theme.clinical;
    // La franja saludable = ÓPTIMO; el color lo pone el tema.
    final optimal = clinical.optimal;

    final recentRecords = downsample(records);
    final axisFmt = axisDateFormat(
      recentRecords.first.date,
      recentRecords.last.date,
    );
    final labelStep = axisLabelStep(recentRecords.length);

    final List<FlSpot> spots = [];
    double minV = recentRecords.first.heartRate.toDouble();
    double maxV = minV;
    for (int i = 0; i < recentRecords.length; i++) {
      final v = recentRecords[i].heartRate.toDouble();
      spots.add(FlSpot(i.toDouble(), v));
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    // La banda saludable 60–100 bpm siempre debe quedar visible.
    const double bandLo = 60, bandHi = 100;
    minV = math.min(minV, bandLo - 5);
    maxV = math.max(maxV, bandHi + 5);
    final double minDisplay = (minV - 5).floorToDouble();
    final double maxDisplay = (maxV + 5).ceilToDouble();

    // Zonas del SERVIDOR (dispositivo/sexo/edad del paciente). Sin zonas del
    // servidor, se cae al fallback offline 60–100 en el tono óptimo.
    final serverZones = bandRangeAnnotations(
      'HEART_RATE',
      palette: clinical,
      minY: minDisplay,
      maxY: maxDisplay,
      opacity: 0.10,
    );
    final hasServerZones = serverZones.horizontalRangeAnnotations.isNotEmpty;

    final RangeAnnotations rangeAnnotations = hasServerZones
        ? serverZones
        : RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: bandLo,
                y2: bandHi,
                color: optimal.accent.withValues(alpha: 0.15),
              ),
            ],
          );
    final ExtraLinesData extraLines = hasServerZones
        ? const ExtraLinesData()
        : ExtraLinesData(
            extraLinesOnTop: false,
            horizontalLines: [
              for (final y in const [bandLo, bandHi])
                HorizontalLine(
                  y: y,
                  color: optimal.accent.withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
            ],
          );

    final double leftInterval = math.max(
      1,
      ((maxDisplay - minDisplay) / 4).roundToDouble(),
    );

    return _chartCard(
      title: l10n.heartRateTitle.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          rangeAnnotations: rangeAnnotations,
          extraLinesData: extraLines,
          gridData: _gridData(),
          titlesData: _axisTitles(recentRecords, axisFmt, labelStep, leftInterval),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              // La serie va en el acento de SU familia (vitals es rojo): una
              // serie no está «bien» ni «mal», así que su color sale de la
              // identidad del indicador, no de la paleta clínica.
              color: family.accent,
              barWidth: _theme.surfaces.chartLineWidth,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 4,
                  color: family.accent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    family.accent.withValues(alpha: 0.1),
                    family.accent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      legend: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: optimal.accent.withValues(alpha: 0.3),
              border: Border.all(
                color: optimal.accent.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.historyTargetZone,
            style: _theme.type.meta.copyWith(fontSize: 10),
          ),
          const SizedBox(width: 16),
          Container(width: 12, height: 2, color: family.accent),
          const SizedBox(width: 4),
          Text(
            l10n.heartRateSeriesLabel,
            style: _theme.type.meta.copyWith(fontSize: 10),
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
    List<VitalSignRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final pdf = pw.Document();

    final List<List<String>> tableData = [
      [
        l10n.historyColDate,
        l10n.exportColSysDia,
        l10n.exportColHrShort,
        l10n.exportColStatus,
      ],
      ...records.map((r) {
        String status = BpCategory.of(r.systolic, r.diastolic).label(l10n);
        return [
          DateFormat('dd MMM yyyy').format(r.date),
          '${r.systolic}/${r.diastolic}',
          r.heartRate.toString(),
          status,
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
                l10n.vitalsPdfTitle,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
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
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
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
        filename: 'vital_signs_history.pdf',
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
    List<VitalSignRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    List<List<dynamic>> rows = [
      [
        l10n.historyColDate,
        l10n.exportColSystolic,
        l10n.exportColDiastolic,
        l10n.exportColHeartRate,
        l10n.exportColStatus,
        l10n.exportColActivityState,
        l10n.exportColSymptom,
        l10n.exportColComment,
      ],
      ...records.map((r) {
        String status = BpCategory.of(r.systolic, r.diastolic).label(l10n);
        return [
          DateFormat('dd/MM/yyyy HH:mm').format(r.date),
          r.systolic,
          r.diastolic,
          r.heartRate,
          status,
          r.activityState ?? '',
          r.symptom ?? '',
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
              name: 'vital_signs_history.csv',
              mimeType: 'text/csv',
            ),
          ],
          subject: l10n.vitalsShareCsvSubject,
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
      await VitalSignsRepository.instance.delete(id);
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

  Widget _buildHistoryItem(VitalSignRecord record, AppLocalizations l10n) {
    final theme = _theme;
    final BpCategory bpCat = BpCategory.of(record.systolic, record.diastolic);
    final String statusLabel = bpCat.label(l10n);

    return MeasurementHistoryCard(
      date: record.date,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.systolic}/${record.diastolic}',
            style: theme.type.numeralSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(width: 4),
          Text(
            'mmHg',
            style: theme.type.numeralUnit.copyWith(fontSize: 11),
          ),
          const SizedBox(width: 12),
          Icon(Icons.favorite, size: 12, color: _family.accent),
          const SizedBox(width: 2),
          Text(
            '${record.heartRate} bpm',
            style: theme.type.numeralUnit.copyWith(fontSize: 12),
          ),
        ],
      ),
      // Era una insignia calcada a mano con el color de FÁBRICA del
      // clasificador (`bpCat.color`), que ignoraba el tema y
      // además siempre se dibujaba suave. StatusChip pide el ESTADO y deja
      // que el tema resuelva el acabado: sólido en «Pulso Clínico», suave en
      // «Consulta Serena». Mismo texto, mismo sitio.
      trailing: StatusChip(
        status: bpCat.status,
        label: statusLabel,
        icon: iconForStatus(bpCat.status),
      ),
    );
  }
}
