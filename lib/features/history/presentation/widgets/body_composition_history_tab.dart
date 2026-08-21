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
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/metric_history_scaffold.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Las series del análisis de composición corporal que la gráfica del historial
/// puede dibujar. Cada una es una serie única con su propia unidad; la báscula de
/// bioimpedancia guarda todas, pero hasta ahora solo se pintaba el % de grasa.
enum CompMetric {
  bodyFat,
  muscle,
  visceral,
  metabolicAge,
  bodyWater,
  boneMass,
  bmr,
}

/// Configuración de una serie de composición: de dónde sale el valor, el título
/// de la tarjeta (con su unidad), cuántos decimales rotula el eje y —si existe—
/// el código de referencia del servidor para pintar las zonas de fondo.
///
/// A diferencia de lípidos, aquí NO se dibujan cortes fijos: la interpretación de
/// la composición depende de sexo/edad/dispositivo y la da el servidor
/// ([bandRangeAnnotations]). Sin bandas aplicables → línea limpia, sin inventar
/// nada en el cliente.
class _CompSeriesSpec {
  const _CompSeriesSpec({
    required this.value,
    required this.title,
    this.yDecimals = 0,
    this.bandCode,
  });

  /// Lee el valor de la serie del registro (null si esa toma no lo trae).
  final double? Function(BodyCompositionRecord) value;

  /// Título de la tarjeta de la gráfica (ya localizado; se muestra en mayúsculas).
  final String title;

  /// Decimales del eje izquierdo (0 para niveles/edad/kcal, 1 para %/masa, 2 masa ósea).
  final int yDecimals;

  /// Código de indicador del servidor para las zonas de referencia; null si esa
  /// serie no tiene bandas (p. ej. la edad metabólica).
  final String? bandCode;
}

/// Historial de composición corporal. La estructura común (mensaje superior,
/// filtro, chips que reparten la gráfica entre series, la gráfica, export y la
/// lista con borrado/edición y paginación) la aporta [MetricHistoryScaffold];
/// aquí solo vive lo específico de composición: las gráficas —una por medida que
/// hasta ahora se guardaba pero no se pintaba—, la tarjeta de medición y los
/// export.
class BodyCompositionHistoryTab extends StatefulWidget {
  const BodyCompositionHistoryTab({super.key});

  @override
  State<BodyCompositionHistoryTab> createState() =>
      _BodyCompositionHistoryTabState();
}

class _BodyCompositionHistoryTabState extends State<BodyCompositionHistoryTab> {
  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «composición corporal»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.bodyComposition);

  /// Configuración de cada serie. Se construye por `build` porque los rótulos
  /// dependen de la localización.
  Map<CompMetric, _CompSeriesSpec> _specs(AppLocalizations l10n) => {
    CompMetric.bodyFat: _CompSeriesSpec(
      value: (r) => r.bodyFatPercent,
      title: l10n.compositionBodyFat,
      yDecimals: 1,
      bandCode: 'BODY_FAT',
    ),
    CompMetric.muscle: _CompSeriesSpec(
      value: (r) => r.musclePct,
      title: '${l10n.compositionSkeletalMuscle} (%)',
      yDecimals: 1,
      bandCode: 'MUSCLE_PCT',
    ),
    CompMetric.visceral: _CompSeriesSpec(
      value: (r) => r.visceralFatLevel?.toDouble(),
      title: l10n.compositionVisceralFat,
      bandCode: 'VISCERAL_FAT',
    ),
    CompMetric.metabolicAge: _CompSeriesSpec(
      value: (r) => r.metabolicAge?.toDouble(),
      title: l10n.compositionMetabolicAge,
    ),
    CompMetric.bodyWater: _CompSeriesSpec(
      value: (r) => r.bodyWaterPercent,
      title: '${l10n.compositionBodyWater} (%)',
      yDecimals: 1,
      bandCode: 'BODY_WATER',
    ),
    CompMetric.boneMass: _CompSeriesSpec(
      value: (r) => r.boneMassKg,
      title: '${l10n.compositionBoneMass} (kg)',
      yDecimals: 2,
      bandCode: 'BONE_MASS',
    ),
    CompMetric.bmr: _CompSeriesSpec(
      value: (r) => r.bmrKcal?.toDouble(),
      title: l10n.compositionBmr,
      bandCode: 'BMR',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<BodyCompositionRepository>();
    final specs = _specs(l10n);

    return MetricHistoryScaffold<BodyCompositionRecord, CompMetric>(
      isLoaded: repo.isLoaded,
      records: repo.items,
      dateOf: (r) => r.date,
      idOf: (r) => r.id,
      family: _family,
      initialMetric: CompMetric.bodyFat,
      // Chips con rótulos cortos: la barra desplaza en horizontal, así que caben
      // las siete series sin desbordar. El nombre largo va en el título de la
      // gráfica, que el andamiaje recorta con «…».
      metricChips: [
        MetricChip(
          value: CompMetric.bodyFat,
          label: l10n.dashboardCompositionFat,
        ),
        MetricChip(
          value: CompMetric.muscle,
          label: l10n.dashboardCompositionMuscle,
        ),
        MetricChip(
          value: CompMetric.visceral,
          label: l10n.dashboardCompositionVisceral,
        ),
        MetricChip(
          value: CompMetric.metabolicAge,
          label: l10n.exportColMetabolicAge,
        ),
        MetricChip(
          value: CompMetric.bodyWater,
          label: l10n.exportColBodyWater,
        ),
        MetricChip(
          value: CompMetric.boneMass,
          label: l10n.exportColBoneMass,
        ),
        MetricChip(value: CompMetric.bmr, label: l10n.dashboardCompositionBmr),
      ],
      // Mensaje superior: encabeza el indicador con el color de su FAMILIA; no
      // afirma nada sobre la salud, solo dice de qué habla el panel.
      bannerBuilder: (_) => MetricHighlightBanner(
        tone: _family,
        icon: Icons.accessibility_new,
        title: l10n.historyGoodJob,
        subtitle: l10n.historyGoalProgress,
      ),
      chartBuilder: (metric, ascending, filterLabel) =>
          _buildChart(l10n, specs[metric]!, ascending, filterLabel),
      itemBuilder: (r) => _buildHistoryItem(r, l10n),
      onEdit: (r) => context.push('/record-body-composition', extra: r),
      onDelete: BodyCompositionRepository.instance.delete,
      onExportPdf: (records) => _exportPdf(records, l10n),
      onExportCsv: (records) => _exportCsv(records, l10n),
      emptyIcon: Icons.accessibility_new,
      emptyText: l10n.noDataYet,
      emptyActionLabel: l10n.completeBodyProfile,
      onEmptyAction: () => context.push('/record-body-composition'),
    );
  }

  /// Gráfica de una serie de composición: una línea del color de la familia y,
  /// si el servidor trae bandas para esa medida (dispositivo/sexo/edad del
  /// paciente), sus zonas de referencia de fondo. Solo se trazan las tomas que
  /// traen esa serie (cada medida es opcional), así que si la serie elegida no se
  /// midió nunca la tarjeta se oculta y la lista de abajo sigue visible.
  Widget _buildChart(
    AppLocalizations l10n,
    _CompSeriesSpec spec,
    List<BodyCompositionRecord> records,
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

    // Aire alrededor de la serie; si el rango es plano, un mínimo relativo.
    final double span = (maxV - minV).abs();
    final double pad = span == 0 ? (maxV.abs() * 0.1 + 1) : span * 0.2;
    double minDisplay = minV - pad;
    final double maxDisplay = maxV + pad;
    // Los indicadores de composición no toman valores negativos.
    if (minV >= 0 && minDisplay < 0) minDisplay = 0;
    final double leftInterval = math.max(
      spec.yDecimals >= 2 ? 0.5 : 1.0,
      (maxDisplay - minDisplay) / 4,
    );

    // Zonas del SERVIDOR recortadas al dominio visible; vacío si no hay bandas
    // aplicables (o si la serie no tiene código de referencia).
    final RangeAnnotations zones = spec.bandCode == null
        ? const RangeAnnotations()
        : bandRangeAnnotations(
            spec.bandCode!,
            palette: _theme.clinical,
            minY: minDisplay,
            maxY: maxDisplay,
          );
    final bool hasZones = zones.horizontalRangeAnnotations.isNotEmpty;

    final dates = [for (final r in recent) r.date];

    return TrendChartCard(
      title: spec.title.toUpperCase(),
      filterLabel: filterLabel,
      chart: LineChart(
        LineChartData(
          minY: minDisplay,
          maxY: maxDisplay,
          rangeAnnotations: zones,
          gridData: trendGridData(_theme),
          titlesData: trendAxisTitles(
            _theme,
            dates: dates,
            fmt: axisFmt,
            labelStep: labelStep,
            leftInterval: leftInterval,
            yDecimals: spec.yDecimals,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // La serie va en el acento de SU familia (composición): una serie no
            // está «bien» ni «mal»; su color sale de la identidad del indicador,
            // no de la paleta clínica. El juicio lo dan las zonas del servidor.
            trendLineBar(
              _theme,
              spots,
              family.accent,
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
              Text(
                spec.title,
                style: _theme.type.meta.copyWith(fontSize: 10),
              ),
            ],
          ),
          // Solo cuando el servidor aporta zonas: su clave de leyenda, igual que
          // en la gráfica de frecuencia cardíaca.
          if (hasZones)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _theme.clinical.optimal.accent.withValues(
                      alpha: 0.3,
                    ),
                    border: Border.all(
                      color: _theme.clinical.optimal.accent.withValues(
                        alpha: 0.6,
                      ),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.historyTargetZone,
                  style: _theme.type.meta.copyWith(fontSize: 10),
                ),
              ],
            ),
        ],
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
          if (r.bodyFatPercent != null) '${_num(r.bodyFatPercent)}%' else '-',
          if (r.muscleMassKg != null) '${_num(r.muscleMassKg)}kg' else '-',
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
    final List<List<dynamic>> rows = [
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
    final String csvData = csv.encode(rows);
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

  /// Línea compacta con los demás valores del registro (músculo %/kg, visceral,
  /// edad metabólica, TMB) — así la lista muestra de un vistazo lo que antes solo
  /// quedaba guardado. `null` cuando no hay ninguno.
  String? _secondaryLine(BodyCompositionRecord r, AppLocalizations l10n) {
    final parts = <String>[
      if (r.musclePct != null)
        '${l10n.dashboardCompositionMuscle} ${_num(r.musclePct)}%',
      if (r.musclePct == null && r.muscleMassKg != null)
        '${l10n.dashboardCompositionMuscle} ${_num(r.muscleMassKg)}kg',
      if (r.visceralFatLevel != null)
        '${l10n.dashboardCompositionVisceral} ${r.visceralFatLevel}',
      if (r.metabolicAge != null)
        '${l10n.compositionMetabolicAge} ${r.metabolicAge}',
      if (r.bmrKcal != null) '${r.bmrKcal} kcal',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Formatea un valor sin el «.0» sobrante (26.0 → «26»; 2.35 se conserva).
  String _num(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  Widget _buildHistoryItem(
    BodyCompositionRecord record,
    AppLocalizations l10n,
  ) {
    final theme = _theme;
    final double defaultFat = record.bodyFatPercent ?? 0.0;
    final FatCategory fatCat = FatCategory.of(defaultFat);
    final String statusLabel = fatCat.label(l10n);

    return MeasurementHistoryCard(
      date: record.date,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            record.bodyFatPercent != null ? _num(record.bodyFatPercent) : 'N/A',
            style: theme.type.numeralSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(width: 4),
          Text(
            '% ${l10n.dashboardCompositionFat}',
            style: theme.type.numeralUnit.copyWith(fontSize: 11),
          ),
        ],
      ),
      detail: _secondaryLine(record, l10n),
      // StatusChip pide el ESTADO y deja que el tema resuelva el acabado: sólido
      // en «Pulso Clínico», suave en «Consulta Serena».
      trailing: record.bodyFatPercent != null
          ? StatusChip(
              status: fatCat.status,
              label: statusLabel,
              icon: iconForStatus(fatCat.status),
            )
          : null,
    );
  }
}
