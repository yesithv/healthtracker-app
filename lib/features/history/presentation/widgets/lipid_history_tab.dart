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
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/metric_history_scaffold.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';
import 'dart:typed_data';

/// Las cinco series del panel lipídico que la gráfica del historial puede
/// dibujar. Todas están en la MISMA unidad (mg/dL) y comparten estructura de
/// serie única; lo que cambia entre ellas es el valor que leen del registro, su
/// línea de referencia y la semántica (en HDL, bajo es lo riesgoso).
enum LipidMetric { totalCholesterol, ldl, hdl, vldl, triglycerides }

/// Configuración de una serie lipídica: de dónde sale el valor, su umbral de
/// referencia clínico y si «alto es lo malo». HDL invierte la semántica (la
/// franja deseable es ≥ 60), así que su línea marca el suelo saludable en verde
/// en vez del techo en rojo.
class _LipidSeriesSpec {
  const _LipidSeriesSpec({
    required this.value,
    required this.title,
    required this.refLabel,
    required this.cutoff,
    this.lowIsBad = false,
  });

  /// Lee el valor de la serie del registro (null si esa toma no lo trae).
  final double? Function(LipidRecord) value;

  /// Título de la tarjeta de la gráfica (ya localizado, se muestra en mayúsculas).
  final String title;

  /// Texto de referencia para la leyenda (p. ej. «Ref: < 200 mg/dL»).
  final String refLabel;

  /// Umbral de referencia dibujado como línea discontinua.
  final double cutoff;

  /// `true` cuando quedar POR DEBAJO del umbral es lo riesgoso (HDL).
  final bool lowIsBad;
}

/// Historial del perfil lipídico. La estructura común (mensaje superior, filtro
/// de periodo, chips que reparten la gráfica entre series, la gráfica, export y
/// la lista con borrado/edición y paginación) la aporta [MetricHistoryScaffold];
/// aquí solo vive lo específico de lípidos: las cinco gráficas —una por analito
/// que hasta ahora se guardaba pero no se pintaba—, la tarjeta de medición y los
/// export.
class LipidHistoryTab extends StatefulWidget {
  const LipidHistoryTab({super.key});

  @override
  State<LipidHistoryTab> createState() => _LipidHistoryTabState();
}

class _LipidHistoryTabState extends State<LipidHistoryTab> {
  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «perfil lipídico»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.lipids);

  /// Configuración de cada serie. Se construye por `build` porque los rótulos
  /// dependen de la localización.
  Map<LipidMetric, _LipidSeriesSpec> _specs(AppLocalizations l10n) => {
    LipidMetric.totalCholesterol: _LipidSeriesSpec(
      value: (r) => r.totalCholesterol,
      title: l10n.lipidTotalCholesterol,
      refLabel: l10n.lipidTcRef,
      cutoff: 200,
    ),
    LipidMetric.ldl: _LipidSeriesSpec(
      value: (r) => r.ldl,
      title: l10n.lipidLdl,
      refLabel: l10n.lipidLdlRef,
      cutoff: 100,
    ),
    LipidMetric.hdl: _LipidSeriesSpec(
      value: (r) => r.hdl,
      title: l10n.lipidHdl,
      refLabel: l10n.lipidHdlRef,
      cutoff: 60,
      lowIsBad: true,
    ),
    LipidMetric.vldl: _LipidSeriesSpec(
      value: (r) => r.vldl,
      title: l10n.lipidVldl,
      refLabel: l10n.lipidVldlRef,
      cutoff: 30,
    ),
    LipidMetric.triglycerides: _LipidSeriesSpec(
      value: (r) => r.triglycerides,
      title: l10n.lipidTriglycerides,
      refLabel: l10n.lipidTrigsRef,
      cutoff: 150,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<LipidRepository>();
    final specs = _specs(l10n);

    return MetricHistoryScaffold<LipidRecord, LipidMetric>(
      isLoaded: repo.isLoaded,
      records: repo.items,
      dateOf: (r) => r.date,
      idOf: (r) => r.id,
      family: _family,
      initialMetric: LipidMetric.totalCholesterol,
      // Chips con rótulos cortos: la barra desplaza en horizontal, así que caben
      // las cinco series sin desbordar. El nombre largo va en el título de la
      // gráfica, que el andamiaje recorta con «…».
      metricChips: [
        MetricChip(
          value: LipidMetric.totalCholesterol,
          label: l10n.exportColTotalCholShort,
        ),
        MetricChip(value: LipidMetric.ldl, label: l10n.mhxLdl),
        MetricChip(value: LipidMetric.hdl, label: l10n.mhxHdl),
        MetricChip(value: LipidMetric.vldl, label: l10n.lipidVldl),
        MetricChip(
          value: LipidMetric.triglycerides,
          label: l10n.exportColTrigsShort,
        ),
      ],
      // Mensaje superior: encabeza el indicador con el color de su FAMILIA; no
      // afirma nada sobre la salud, solo dice de qué habla el panel.
      bannerBuilder: (_) => MetricHighlightBanner(
        tone: _family,
        icon: Icons.bloodtype,
        title: l10n.historyGoodJob,
        subtitle: l10n.historyGoalProgress,
      ),
      chartBuilder: (metric, ascending, filterLabel) =>
          _buildChart(l10n, specs[metric]!, ascending, filterLabel),
      itemBuilder: (r) => _buildHistoryItem(r, l10n),
      onEdit: (r) => context.push('/record-lipid', extra: r),
      onDelete: LipidRepository.instance.delete,
      onExportPdf: (records) => _exportPdf(records, l10n),
      onExportCsv: (records) => _exportCsv(records, l10n),
      emptyIcon: Icons.bloodtype,
      emptyText: l10n.noDataYet,
      emptyActionLabel: l10n.recordLabResults,
      onEmptyAction: () => context.push('/record-lipid'),
    );
  }

  /// Gráfica de una serie lipídica: una línea del color de la familia y su línea
  /// de referencia discontinua. Solo se trazan las tomas que traen esa serie
  /// (cada analito es opcional en el registro), así que si el analito elegido no
  /// se midió nunca la tarjeta se oculta y la lista de abajo sigue visible.
  Widget _buildChart(
    AppLocalizations l10n,
    _LipidSeriesSpec spec,
    List<LipidRecord> records,
    String filterLabel,
  ) {
    final family = _family;
    final valid = records.where((r) => spec.value(r) != null).toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    // Muestreo uniforme de TODA la lista filtrada (conserva primero y último).
    final recent = downsample(valid);
    final axisFmt = axisDateFormat(recent.first.date, recent.last.date);
    final labelStep = axisLabelStep(recent.length);

    final List<FlSpot> spots = [];
    double minV = spec.value(recent.first)!;
    double maxV = minV;
    for (int i = 0; i < recent.length; i++) {
      final v = spec.value(recent[i])!;
      spots.add(FlSpot(i.toDouble(), v));
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    // La línea de referencia siempre debe quedar dentro del encuadre.
    minV = math.min(minV, spec.cutoff);
    maxV = math.max(maxV, spec.cutoff);
    final double minDisplay = math.max(0, (minV - 20).floorToDouble());
    final double maxDisplay = (maxV + 20).ceilToDouble();
    final double leftInterval = math.max(
      1,
      ((maxDisplay - minDisplay) / 4).roundToDouble(),
    );

    // «Alto es malo» → la línea marca el techo en rojo de ALERTA. HDL invierte:
    // marca el suelo saludable en el verde ÓPTIMO.
    final Color refColor = spec.lowIsBad
        ? _theme.clinical.optimal.accent
        : _theme.clinical.alert.accent;

    final dates = [for (final r in recent) r.date];

    return TrendChartCard(
      title: spec.title.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          extraLinesData: ExtraLinesData(
            extraLinesOnTop: false,
            horizontalLines: [
              HorizontalLine(
                y: spec.cutoff,
                color: refColor.withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
            ],
          ),
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
            // La serie va en el acento de SU familia (lípidos): una serie no está
            // «bien» ni «mal», su color sale de la identidad del indicador, no de
            // la paleta clínica. El juicio clínico lo da la línea de referencia.
            trendLineBar(_theme, spots, family.accent),
          ],
        ),
      ),
      // Leyenda en `Wrap` para que el rótulo de referencia largo («Ref: < 200
      // mg/dL») baje de línea en vez de desbordar la tarjeta.
      legend: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 2, color: family.accent),
              const SizedBox(width: 4),
              Text(spec.title, style: _theme.type.meta.copyWith(fontSize: 10)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dashSwatch(refColor),
              const SizedBox(width: 4),
              Text(
                spec.refLabel,
                style: _theme.type.meta.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Muestra de línea discontinua para la leyenda de la referencia.
  Widget _dashSwatch(Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (int i = 0; i < 3; i++) ...[
        Container(width: 4, height: 2, color: color.withValues(alpha: 0.6)),
        if (i < 2) const SizedBox(width: 2),
      ],
    ],
  );

  Future<void> _exportPdf(
    List<LipidRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final pdf = pw.Document();

    final List<List<String>> tableData = [
      [
        l10n.historyColDate,
        l10n.exportColTotalCholShort,
        'LDL',
        'HDL',
        l10n.exportColTrigsShort,
      ],
      ...records.map((r) {
        return [
          DateFormat('dd MMM yyyy').format(r.date),
          _num(r.totalCholesterol),
          _num(r.ldl),
          _num(r.hdl),
          _num(r.triglycerides),
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
                l10n.lipidPdfTitle,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.pink900,
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
                color: PdfColors.pink800,
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
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    try {
      final ok = await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'lipid_profile_history.pdf',
      );
      showShareFeedback(
        messenger,
        theme,
        l10n,
        ok ? ShareOutcome.success : ShareOutcome.silent,
      );
    } catch (e) {
      debugLogError('Export.lipid', e);
      showShareFeedback(messenger, theme, l10n, ShareOutcome.error);
    }
  }

  Future<void> _exportCsv(
    List<LipidRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final List<List<dynamic>> rows = [
      [
        l10n.historyColDate,
        l10n.exportColTotalCholesterol,
        'LDL',
        'HDL',
        'VLDL',
        l10n.exportColTriglycerides,
        l10n.exportColLabName,
        l10n.exportColComment,
      ],
      ...records.map((r) {
        return [
          DateFormat('dd/MM/yyyy HH:mm').format(r.date),
          r.totalCholesterol ?? '',
          r.ldl ?? '',
          r.hdl ?? '',
          r.vldl ?? '',
          r.triglycerides ?? '',
          r.labName ?? '',
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
              name: 'lipid_profile_history.csv',
              mimeType: 'text/csv',
            ),
          ],
          subject: l10n.lipidShareCsvSubject,
        ),
      ),
    );
    showShareFeedback(messenger, theme, l10n, outcome);
  }

  /// Línea de contexto compacta con los OTROS analitos del registro (LDL, HDL,
  /// VLDL, triglicéridos): así la lista muestra de un vistazo los valores que
  /// antes solo quedaban guardados. `null` cuando no hay ninguno.
  String? _secondaryLine(LipidRecord r) {
    final parts = <String>[
      if (r.ldl != null) 'LDL ${_num(r.ldl)}',
      if (r.hdl != null) 'HDL ${_num(r.hdl)}',
      if (r.vldl != null) 'VLDL ${_num(r.vldl)}',
      if (r.triglycerides != null) 'TG ${_num(r.triglycerides)}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Formatea un valor de laboratorio sin el «.0» sobrante (130.0 → «130»).
  String _num(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  Widget _buildHistoryItem(LipidRecord record, AppLocalizations l10n) {
    final theme = _theme;
    final LipidStatus overall = overallLipidStatus(record);
    final String statusLabel = overall.label(l10n);

    return MeasurementHistoryCard(
      date: record.date,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            record.totalCholesterol != null
                ? _num(record.totalCholesterol)
                : 'N/A',
            style: theme.type.numeralSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(width: 4),
          Text(
            'mg/dL (CT)',
            style: theme.type.numeralUnit.copyWith(fontSize: 11),
          ),
        ],
      ),
      // Los demás analitos del registro, que antes se guardaban sin mostrarse.
      detail: _secondaryLine(record),
      // StatusChip pide el ESTADO y deja que el tema resuelva el acabado: sólido
      // en «Pulso Clínico», suave en «Consulta Serena».
      trailing: StatusChip(
        status: overall.status,
        label: statusLabel,
        icon: iconForStatus(overall.status),
      ),
    );
  }
}
