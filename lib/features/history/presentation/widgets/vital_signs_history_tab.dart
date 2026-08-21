import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
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
import 'package:myvitals_healthtracker_app/core/widgets/trend_chart_card.dart';
import 'package:myvitals_healthtracker_app/core/charts/trend_line_chart.dart';
import 'package:myvitals_healthtracker_app/core/ranges/chart_bands.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/metric_history_scaffold.dart';
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

/// Historial de signos vitales. La estructura común (mensaje superior, filtro,
/// chips, gráfica, export, lista con borrado/edición y paginación) la aporta
/// [MetricHistoryScaffold]; aquí solo vive lo específico de vitales: las dos
/// gráficas, la tarjeta de medición y los export.
class VitalSignsHistoryTab extends StatefulWidget {
  const VitalSignsHistoryTab({super.key});

  @override
  State<VitalSignsHistoryTab> createState() => _VitalSignsHistoryTabState();
}

class _VitalSignsHistoryTabState extends State<VitalSignsHistoryTab> {
  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «signos vitales»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.vitals);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<VitalSignsRepository>();

    return MetricHistoryScaffold<VitalSignRecord, VitalMetric>(
      isLoaded: repo.isLoaded,
      records: repo.items,
      dateOf: (r) => r.date,
      idOf: (r) => r.id,
      family: _family,
      initialMetric: VitalMetric.bloodPressure,
      metricChips: [
        MetricChip(
          value: VitalMetric.bloodPressure,
          label: l10n.vitalMetricBpShort,
        ),
        MetricChip(value: VitalMetric.heartRate, label: l10n.vitalMetricHrShort),
      ],
      // Mensaje superior: encabeza el indicador con el color de su FAMILIA;
      // no afirma nada sobre la salud, solo dice de qué habla el panel.
      bannerBuilder: (_) => MetricHighlightBanner(
        tone: _family,
        icon: Icons.favorite,
        title: l10n.historyGoodJob,
        subtitle: l10n.historyGoalProgress,
      ),
      chartBuilder: (metric, ascending, filterLabel) =>
          _buildChartContainer(l10n, metric, ascending, filterLabel),
      itemBuilder: (r) => _buildHistoryItem(r, l10n),
      onEdit: (r) => context.push('/record-vital-signs', extra: r),
      onDelete: VitalSignsRepository.instance.delete,
      onExportPdf: (records) => _exportPdf(records, l10n),
      onExportCsv: (records) => _exportCsv(records, l10n),
      emptyIcon: Icons.favorite_border,
      emptyText: l10n.noDataYet,
      emptyActionLabel: l10n.recordVitalsAction,
      onEmptyAction: () => context.push('/record-vital-signs'),
    );
  }

  /// Despacha la gráfica según el indicador elegido en la barra de chips.
  Widget _buildChartContainer(
    AppLocalizations l10n,
    VitalMetric metric,
    List<VitalSignRecord> records,
    String filterLabel,
  ) {
    if (records.isEmpty) return const SizedBox.shrink();
    return switch (metric) {
      VitalMetric.bloodPressure =>
        _buildBloodPressureChart(l10n, records, filterLabel),
      VitalMetric.heartRate =>
        _buildHeartRateChart(l10n, records, filterLabel),
    };
  }

  /// Índices de [recentRecords] cuya lectura trae un síntoma relevante
  /// (mareo/dolor/fatiga); «normal»/ausente no cuentan. Alinea 1:1 con los
  /// puntos de la gráfica, que se construyen en el mismo orden.
  Set<int> _flaggedSymptoms(
    List<VitalSignRecord> recentRecords,
    AppLocalizations l10n,
  ) => {
    for (int i = 0; i < recentRecords.length; i++)
      if (_symptomLabel(recentRecords[i].symptom, l10n) != null) i,
  };

  /// Ítem de leyenda del marcador de síntoma (círculo ámbar + rótulo).
  Widget _symptomLegend(AppLocalizations l10n) {
    final marker = _theme.clinical.caution.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 16),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.symptomMarkerLegend,
          style: _theme.type.meta.copyWith(fontSize: 10),
        ),
      ],
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
    final flagged = _flaggedSymptoms(recentRecords, l10n);
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
    final dates = [for (final r in recentRecords) r.date];

    return TrendChartCard(
      title: l10n.bloodPressureTitle.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          gridData: trendGridData(_theme),
          titlesData: trendAxisTitles(
            _theme,
            dates: dates,
            fmt: axisFmt,
            labelStep: labelStep,
            leftInterval: 20,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Solo la serie superior (sistólica) lleva el marcador de síntoma,
            // para no duplicar el punto por lectura.
            trendLineBar(_theme, spotsSys, family.accent, flagged: flagged),
            trendLineBar(_theme, spotsDia, cool),
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
          if (flagged.isNotEmpty) _symptomLegend(l10n),
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
    final flagged = _flaggedSymptoms(recentRecords, l10n);

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
    final dates = [for (final r in recentRecords) r.date];

    return TrendChartCard(
      title: l10n.heartRateTitle.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          rangeAnnotations: rangeAnnotations,
          extraLinesData: extraLines,
          gridData: trendGridData(_theme),
          titlesData: trendAxisTitles(
            _theme,
            dates: dates,
            fmt: axisFmt,
            labelStep: labelStep,
            leftInterval: leftInterval,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // La serie va en el acento de SU familia (vitals es rojo): una serie
            // no está «bien» ni «mal», así que su color sale de la identidad del
            // indicador, no de la paleta clínica. Los puntos con síntoma se
            // marcan en ámbar vía [flagged].
            trendLineBar(
              _theme,
              spots,
              family.accent,
              flagged: flagged,
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
          if (flagged.isNotEmpty) _symptomLegend(l10n),
        ],
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
        final String status = BpCategory.of(r.systolic, r.diastolic).label(l10n);
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
    } catch (e) {
      debugLogError('Export.vitalSigns', e);
      showShareFeedback(messenger, theme, l10n, ShareOutcome.error);
    }
  }

  Future<void> _exportCsv(
    List<VitalSignRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final List<List<dynamic>> rows = [
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
        final String status = BpCategory.of(r.systolic, r.diastolic).label(l10n);
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
    final String csvData = csv.encode(rows);
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

  /// Etiqueta localizada del estado de actividad; `null` si no se registró.
  String? _activityLabel(String? raw, AppLocalizations l10n) => switch (raw) {
    'reposo' => l10n.activityRest,
    'ejercicio' => l10n.activityExercise,
    'post-op' => l10n.activityPostOp,
    _ => null,
  };

  /// Etiqueta localizada del síntoma. «normal» y `null` se omiten: no aportan
  /// contexto clínico y solo harían ruido en la línea.
  String? _symptomLabel(String? raw, AppLocalizations l10n) => switch (raw) {
    'mareo' => l10n.symptomDizziness,
    'dolor' => l10n.symptomPain,
    'fatiga' => l10n.symptomFatigue,
    _ => null,
  };

  /// Línea de contexto compacta de una lectura (p. ej. «Ejercicio · Mareo»).
  /// `null` cuando no hay actividad ni síntoma relevante que mostrar.
  String? _contextLine(VitalSignRecord r, AppLocalizations l10n) {
    final parts = <String>[
      ?_activityLabel(r.activityState, l10n),
      ?_symptomLabel(r.symptom, l10n),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _buildHistoryItem(VitalSignRecord record, AppLocalizations l10n) {
    final theme = _theme;
    final BpCategory bpCat = BpCategory.of(record.systolic, record.diastolic);
    final String statusLabel = bpCat.label(l10n);

    return MeasurementHistoryCard(
      date: record.date,
      detail: _contextLine(record, l10n),
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.systolic}/${record.diastolic}',
            style: theme.type.numeralSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(width: 4),
          Text('mmHg', style: theme.type.numeralUnit.copyWith(fontSize: 11)),
          const SizedBox(width: 12),
          Icon(Icons.favorite, size: 12, color: _family.accent),
          const SizedBox(width: 2),
          Text(
            '${record.heartRate} bpm',
            style: theme.type.numeralUnit.copyWith(fontSize: 12),
          ),
        ],
      ),
      // StatusChip pide el ESTADO y deja que el tema resuelva el acabado: sólido
      // en «Pulso Clínico», suave en «Consulta Serena».
      trailing: StatusChip(
        status: bpCat.status,
        label: statusLabel,
        icon: iconForStatus(bpCat.status),
      ),
    );
  }
}
