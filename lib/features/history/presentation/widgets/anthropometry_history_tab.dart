import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

import 'dart:math' as math;

import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/clinical_palette.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/metric_palette.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/charts/chart_series.dart';
import 'package:myvitals_healthtracker_app/core/charts/trend_line_chart.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/core/widgets/action_button.dart';
import 'package:myvitals_healthtracker_app/core/ranges/chart_bands.dart';
import 'package:myvitals_healthtracker_app/core/widgets/bmi_status_badge.dart';
import 'package:myvitals_healthtracker_app/core/widgets/measurement_history_card.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_chip_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/metric_highlight_banner.dart';
import 'package:myvitals_healthtracker_app/core/widgets/trend_chart_card.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/metric_history_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';
import 'dart:typed_data';

/// Métricas que la gráfica del historial de antropometría puede dibujar.
///
/// Los tres primeros son ÍNDICES con interpretación clínica (bandas de riesgo);
/// el resto son PERÍMETROS crudos que solo se siguen como tendencia (sin bandas,
/// porque no tienen cortes estándar reconocidos).
enum AnthroMetric { bmi, whtr, whr, waist, hip, abdomen, arm, leg, chest }

/// Zonas de referencia OFFLINE de una métrica (cuando el servidor no sirve bandas).
///
/// [bandLo]/[bandHi] es la franja saludable (se pinta como fondo), [lines] son los
/// cortes que se marcan con líneas punteadas, y [displayMin]/[displayMax] fuerzan
/// a que la zona objetivo siempre quede dentro del dominio visible del eje Y.
/// `null` como referencia entera = métrica sin interpretación clínica (perímetros).
class _MetricRef {
  const _MetricRef({
    required this.lines,
    this.bandLo,
    this.bandHi,
    required this.displayMin,
    required this.displayMax,
  });

  final List<double> lines;
  final double? bandLo;
  final double? bandHi;

  // La franja saludable de estas métricas siempre representa el rango ÓPTIMO
  // (cortes OMS/Ashwell); ningún constructor necesita variar el estado.
  final ClinicalStatus bandStatus = ClinicalStatus.optimal;
  final double displayMin;
  final double displayMax;

  bool get hasBand => bandLo != null && bandHi != null;
}

/// Todo lo que la gráfica necesita para dibujar una [AnthroMetric] concreta:
/// de dónde sacar el valor, el código de banda del servidor, cómo rotular ejes y
/// leyenda, y qué medida falta cuando no hay datos.
class _MetricSpec {
  const _MetricSpec({
    required this.value,
    required this.indicatorCode,
    required this.yDecimals,
    required this.chipLabel,
    required this.title,
    required this.seriesLabel,
    required this.needsMeasure,
    required this.ref,
  });

  /// Extractor del valor de la serie; `null` cuando el registro no lo tiene.
  final double? Function(AnthropometricRecord) value;

  /// Código para las bandas del servidor (`bandRangeAnnotations`); `null` en los
  /// perímetros crudos, que nunca llevan bandas clínicas.
  final String? indicatorCode;
  final int yDecimals;
  final String chipLabel;
  final String title;
  final String seriesLabel;

  /// Medida que hay que registrar para que la métrica tenga datos, ya localizada.
  /// `null` en el IMC (siempre presente): no muestra estado vacío por métrica.
  final String? needsMeasure;
  final _MetricRef? ref;
}

/// Historial de antropometría. La estructura común (mensaje superior, filtro,
/// chips, gráfica, export, lista con borrado/edición y paginación) la aporta
/// [MetricHistoryScaffold]; aquí solo vive lo específico de antropometría: los
/// descriptores por métrica, la gráfica, la tarjeta de medición y los export.
class AnthropometryHistoryTab extends StatefulWidget {
  const AnthropometryHistoryTab({super.key});

  @override
  State<AnthropometryHistoryTab> createState() =>
      _AnthropometryHistoryTabState();
}

class _AnthropometryHistoryTabState extends State<AnthropometryHistoryTab> {
  /// Orden de aparición de las métricas en el selector.
  static const List<AnthroMetric> _metricOrder = [
    AnthroMetric.bmi,
    AnthroMetric.whtr,
    AnthroMetric.whr,
    AnthroMetric.waist,
    AnthroMetric.hip,
    AnthroMetric.abdomen,
    AnthroMetric.arm,
    AnthroMetric.leg,
    AnthroMetric.chest,
  ];

  ThemeData get _theme => Theme.of(context);

  /// Identidad de la familia «antropometría»: el matiz no cambia con el tema.
  Tone get _family => _theme.metrics.tone(MetricFamily.anthropometry);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<AnthropometricRepository>();
    final gender = context.watch<UserProfileProvider>().userGender;

    return MetricHistoryScaffold<AnthropometricRecord, AnthroMetric>(
      isLoaded: repo.isLoaded,
      records: repo.items,
      dateOf: (r) => r.date,
      idOf: (r) => r.id,
      family: _family,
      initialMetric: AnthroMetric.bmi,
      metricChips: [
        for (final m in _metricOrder)
          // El sexo solo afecta al corte del ICC, no a la etiqueta del chip.
          MetricChip(value: m, label: _metricSpec(m, l10n, '').chipLabel),
      ],
      // Mensaje superior: «vas bien» va en el tono ÓPTIMO, no en el de la
      // familia, porque afirma algo sobre la salud del usuario.
      bannerBuilder: (ascending) => MetricHighlightBanner(
        tone: _theme.clinical.optimal,
        icon: Icons.check_circle_outline,
        title: l10n.historyGoodJob,
        subtitle: _bannerSubtitle(ascending, l10n),
      ),
      chartBuilder: (metric, ascending, filterLabel) => _buildChartContainer(
        l10n,
        ascending,
        filterLabel,
        _metricSpec(metric, l10n, gender),
      ),
      itemBuilder: (r) => _buildHistoryItem(r, l10n),
      onEdit: (r) => context.push('/record-anthropometric', extra: r),
      onDelete: AnthropometricRepository.instance.delete,
      onExportPdf: (records) => _exportPdf(records, l10n),
      onExportCsv: (records) => _exportCsv(records, l10n),
      emptyIcon: Icons.straighten,
      emptyText: l10n.historyNoMeasurements,
      emptyActionLabel: l10n.recordFirstMeasure,
      onEmptyAction: () => context.push('/record-anthropometric'),
    );
  }

  /// Subtítulo del banner: progreso de meta, o la pérdida de peso entre las dos
  /// últimas tomas si la hubo.
  String _bannerSubtitle(
    List<AnthropometricRecord> ascending,
    AppLocalizations l10n,
  ) {
    String subtitle = l10n.historyGoalProgress;
    if (ascending.length >= 2) {
      final last = ascending.last;
      final prev = ascending[ascending.length - 2];
      final diff = prev.weight - last.weight;
      if (diff > 0) {
        subtitle = l10n.historyWeightLoss(diff.toStringAsFixed(1));
      }
    }
    return subtitle;
  }

  /// Descriptor de la métrica [m] resuelto con el idioma y el sexo del perfil (este
  /// último solo mueve el corte del ICC). Concentra en un sitio todo lo variable
  /// entre métricas para que `_buildChartContainer` sea genérico.
  _MetricSpec _metricSpec(
    AnthroMetric m,
    AppLocalizations l10n,
    String gender,
  ) {
    switch (m) {
      case AnthroMetric.bmi:
        return _MetricSpec(
          value: (r) => r.bmi,
          indicatorCode: 'BMI',
          yDecimals: 0,
          chipLabel: l10n.historyBmiUnit,
          title: l10n.historyTrendOf(l10n.historyBmiUnit),
          seriesLabel: l10n.historyBmiUnit,
          needsMeasure: null,
          ref: const _MetricRef(
            lines: [18.5, 24.9],
            bandLo: 18.5,
            bandHi: 24.9,
            displayMin: 17.5,
            displayMax: 26.0,
          ),
        );
      case AnthroMetric.whtr:
        return _MetricSpec(
          value: (r) => r.whtr,
          indicatorCode: 'WHTR',
          yDecimals: 2,
          chipLabel: l10n.whtrShort,
          title: l10n.historyTrendOf(l10n.whtrName),
          seriesLabel: l10n.whtrShort,
          needsMeasure: l10n.measureWaist,
          ref: const _MetricRef(
            lines: [0.5, 0.6],
            bandLo: 0.4,
            bandHi: 0.5,
            displayMin: 0.4,
            displayMax: 0.62,
          ),
        );
      case AnthroMetric.whr:
        final threshold = gender.toLowerCase() == 'male' ? 0.90 : 0.85;
        return _MetricSpec(
          value: (r) => r.whr,
          indicatorCode: 'WHR',
          yDecimals: 2,
          chipLabel: l10n.whrShort,
          title: l10n.historyTrendOf(l10n.whrName),
          seriesLabel: l10n.whrShort,
          needsMeasure: l10n.measureWaistAndHip,
          ref: _MetricRef(
            lines: [threshold],
            bandLo: 0.75,
            bandHi: threshold,
            displayMin: 0.78,
            displayMax: threshold + 0.12,
          ),
        );
      case AnthroMetric.waist:
        return _perimeterSpec((r) => r.waistCm, l10n.circWaist, l10n);
      case AnthroMetric.hip:
        return _perimeterSpec((r) => r.hipCm, l10n.circHip, l10n);
      case AnthroMetric.abdomen:
        return _perimeterSpec(
          (r) => r.lowerAbdomenCm,
          l10n.circAbdomenShort,
          l10n,
        );
      case AnthroMetric.arm:
        return _perimeterSpec((r) => r.armCm, l10n.circArm, l10n);
      case AnthroMetric.leg:
        return _perimeterSpec((r) => r.legCm, l10n.circLeg, l10n);
      case AnthroMetric.chest:
        return _perimeterSpec((r) => r.chestBustCm, l10n.circChestBust, l10n);
    }
  }

  /// Perímetro crudo: solo tendencia en cm, sin bandas clínicas ni cortes.
  _MetricSpec _perimeterSpec(
    double? Function(AnthropometricRecord) value,
    String name,
    AppLocalizations l10n,
  ) {
    return _MetricSpec(
      value: value,
      indicatorCode: null,
      yDecimals: 0,
      chipLabel: name,
      title: l10n.historyTrendOf(name),
      seriesLabel: l10n.unitCm,
      needsMeasure: name,
      ref: null,
    );
  }

  /// Tarjeta que sustituye a la gráfica cuando la métrica seleccionada no tiene
  /// datos (p. ej. el ICA sin cintura registrada). Invita a registrar la medida.
  Widget _metricEmptyState(AppLocalizations l10n, _MetricSpec spec) {
    final surfaces = _theme.surfaces;
    final family = _family;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: surfaces.cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.straighten, size: 40, color: surfaces.inkMuted),
          const SizedBox(height: 12),
          Text(
            spec.needsMeasure == null
                ? l10n.historyNoMeasurements
                : l10n.historyMetricNeedsData(spec.needsMeasure!),
            textAlign: TextAlign.center,
            style: _theme.type.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: l10n.recordFirstMeasure,
            color: family.accent,
            solid: true,
            onPressed: () => context.push('/record-anthropometric'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    AppLocalizations l10n,
    List<AnthropometricRecord> records,
    String filterLabel,
    _MetricSpec spec,
  ) {
    final clinical = _theme.clinical;
    final family = _family;

    // Solo los registros que tienen valor para ESTA métrica: los índices
    // derivados y los perímetros son opcionales y pueden faltar.
    final valued = records.where((r) => spec.value(r) != null).toList();
    if (valued.isEmpty) return _metricEmptyState(l10n, spec);

    // Muestreo uniforme de toda la serie filtrada (conserva primero y último).
    final recentRecords = downsample(valued);
    final axisFmt = axisDateFormat(
      recentRecords.first.date,
      recentRecords.last.date,
    );
    final labelStep = axisLabelStep(recentRecords.length);

    final List<FlSpot> spots = [];
    double minV = spec.value(recentRecords.first)!;
    double maxV = minV;
    for (int i = 0; i < recentRecords.length; i++) {
      final v = spec.value(recentRecords[i])!;
      spots.add(FlSpot(i.toDouble(), v));
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    // La zona de referencia (si la métrica la tiene) siempre debe quedar visible.
    final ref = spec.ref;
    if (ref != null) {
      minV = math.min(minV, ref.displayMin);
      maxV = math.max(maxV, ref.displayMax);
    }

    // Padding proporcional a la escala: fino para ratios (ICA/ICC), entero para
    // IMC y perímetros en cm.
    final pad = spec.yDecimals >= 2 ? 0.03 : 1.0;
    double minDisplay = minV - pad;
    double maxDisplay = maxV + pad;
    if (spec.yDecimals == 0) {
      minDisplay = minDisplay.floorToDouble();
      maxDisplay = maxDisplay.ceilToDouble();
    }
    if (maxDisplay <= minDisplay) maxDisplay = minDisplay + 1;

    // Zonas del SERVIDOR para los índices con `indicatorCode` (los perímetros no
    // llevan bandas clínicas). Sin zonas del servidor, se cae al fallback
    // OMS/Ashwell que trae la métrica en su `ref`.
    final serverZones = spec.indicatorCode == null
        ? const RangeAnnotations(horizontalRangeAnnotations: [])
        : bandRangeAnnotations(
            spec.indicatorCode!,
            palette: clinical,
            minY: minDisplay,
            maxY: maxDisplay,
            opacity: 0.10,
          );
    final hasServerZones = serverZones.horizontalRangeAnnotations.isNotEmpty;
    final useOfflineBand = !hasServerZones && ref != null && ref.hasBand;
    final useOfflineLines =
        !hasServerZones && ref != null && ref.lines.isNotEmpty;
    final refColor = ref == null
        ? family.accent
        : clinical.tone(ref.bandStatus).accent;

    final RangeAnnotations rangeAnnotations;
    if (hasServerZones) {
      rangeAnnotations = serverZones;
    } else if (useOfflineBand) {
      rangeAnnotations = RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(
            y1: ref.bandLo!,
            y2: ref.bandHi!,
            // La franja saludable = ÓPTIMO. Los cortes son OMS/Ashwell; el
            // color lo pone el tema.
            color: refColor.withValues(alpha: 0.15),
          ),
        ],
      );
    } else {
      rangeAnnotations = const RangeAnnotations(horizontalRangeAnnotations: []);
    }

    final ExtraLinesData extraLines = useOfflineLines
        ? ExtraLinesData(
            extraLinesOnTop: false,
            horizontalLines: [
              for (final y in ref.lines)
                HorizontalLine(
                  y: y,
                  color: refColor.withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
            ],
          )
        : const ExtraLinesData();

    // Paso del eje Y: fijo y fino para ratios; repartido en ~4 marcas para el
    // resto.
    final double leftInterval = spec.yDecimals >= 2
        ? 0.05
        : math.max(1, ((maxDisplay - minDisplay) / 4).roundToDouble());
    final bool showTargetLegend = hasServerZones || (ref?.hasBand ?? false);
    final dates = [for (final r in recentRecords) r.date];

    return TrendChartCard(
      title: spec.title,
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
            yDecimals: spec.yDecimals,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // La serie va en el acento de SU familia (antropometría es ámbar):
            // una serie no está «bien» ni «mal», así que NO sale de la paleta
            // clínica sino de la identidad del indicador. Sin curva y con relleno
            // degradado bajo la línea.
            trendLineBar(
              _theme,
              spots,
              family.accent,
              isCurved: false,
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
          if (showTargetLegend) ...[
            Container(
              width: 12,
              height: 8,
              decoration: BoxDecoration(
                color: refColor.withValues(alpha: 0.3),
                border: Border.all(
                  color: refColor.withValues(alpha: 0.6),
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
          ],
          Container(width: 12, height: 2, color: family.accent),
          const SizedBox(width: 4),
          Text(
            spec.seriesLabel,
            style: _theme.type.meta.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(
    List<AnthropometricRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final pdf = pw.Document();

    final List<List<String>> tableData = [
      [
        l10n.historyColDate,
        l10n.historyColWeight,
        l10n.exportColHeight,
        l10n.historyColBmi,
        l10n.historyColCategory,
        l10n.exportColComment,
      ],
      ...records.map((r) {
        final status = BmiCategory.of(r.bmi).label(l10n);
        return [
          DateFormat('dd/MM/yyyy HH:mm').format(r.date),
          r.weight.toStringAsFixed(1),
          r.height.toStringAsFixed(2),
          r.bmi.toStringAsFixed(1),
          status,
          r.comment ?? '',
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
                l10n.historyPdfTitle,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
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
                color: PdfColors.blue800,
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
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    try {
      final ok = await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'anthropometry_history.pdf',
      );
      showShareFeedback(
        messenger,
        theme,
        l10n,
        ok ? ShareOutcome.success : ShareOutcome.silent,
      );
    } catch (e) {
      debugLogError('Export.anthropometry', e);
      showShareFeedback(messenger, theme, l10n, ShareOutcome.error);
    }
  }

  Future<void> _exportCsv(
    List<AnthropometricRecord> records,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = _theme;
    final List<List<dynamic>> rows = [
      [
        l10n.historyColDate,
        l10n.historyColWeight,
        l10n.exportColHeight,
        l10n.historyColBmi,
        l10n.historyColCategory,
        l10n.exportColComment,
      ],
      ...records.map((r) {
        final status = BmiCategory.of(r.bmi).label(l10n);
        return [
          DateFormat('dd/MM/yyyy HH:mm').format(r.date),
          r.weight,
          r.height.toStringAsFixed(2),
          r.bmi.toStringAsFixed(2),
          status,
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
              name: 'anthropometry_history.csv',
              mimeType: 'text/csv',
            ),
          ],
          subject: l10n.historyShareCsvSubject,
        ),
      ),
    );
    showShareFeedback(messenger, theme, l10n, outcome);
  }

  Widget _buildHistoryItem(AnthropometricRecord record, AppLocalizations l10n) {
    final theme = _theme;
    final statusLabel = BmiCategory.of(record.bmi).label(l10n);

    return MeasurementHistoryCard(
      date: record.date,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.weight} kg',
            style: theme.type.numeralSmall.copyWith(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            '(${l10n.historyBmiLabel}: ${record.bmi.toStringAsFixed(1)})',
            style: theme.type.numeralUnit.copyWith(fontSize: 12),
          ),
        ],
      ),
      detail: record.hasCircumferences
          ? _circumferencesLine(record, l10n)
          : null,
      trailing: BmiStatusBadge(bmi: record.bmi, label: statusLabel),
    );
  }

  /// Línea compacta con los perímetros del registro (cm) — visibles p. ej. en la
  /// historia importada del legacy: cintura, cadera, abdomen, brazo, pierna, pecho.
  String _circumferencesLine(AnthropometricRecord r, AppLocalizations l10n) {
    String f(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    // Índices derivados primero (adimensionales, 2 decimales); luego los cm.
    final indices = <String>[
      if (r.whtr != null) '${l10n.whtrShort} ${r.whtr!.toStringAsFixed(2)}',
      if (r.whr != null) '${l10n.whrShort} ${r.whr!.toStringAsFixed(2)}',
    ];
    final parts = <String>[
      if (r.waistCm != null) '${l10n.circWaist} ${f(r.waistCm!)}',
      if (r.hipCm != null) '${l10n.circHip} ${f(r.hipCm!)}',
      if (r.lowerAbdomenCm != null)
        '${l10n.circAbdomenShort} ${f(r.lowerAbdomenCm!)}',
      if (r.armCm != null) '${l10n.circArm} ${f(r.armCm!)}',
      if (r.legCm != null) '${l10n.circLeg} ${f(r.legCm!)}',
      if (r.chestBustCm != null) '${l10n.circChestBust} ${f(r.chestBustCm!)}',
    ];
    final cm = parts.isEmpty ? '' : '${parts.join(' · ')} cm';
    if (indices.isEmpty) return cm;
    final indicesLine = indices.join(' · ');
    return cm.isEmpty ? indicesLine : '$indicesLine · $cm';
  }
}
