import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/ranges/chart_bands.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.watch<BodyCompositionRepository>();
    if (!repo.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

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
              const Icon(Icons.accessibility_new, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.noDataYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ActionButton(
                text: l10n.completeBodyProfile,
                color: const Color(0xFF5C6BC0),
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
              icon: const Icon(
                Icons.filter_list,
                size: 18,
                color: Color(0xFF64748B),
              ),
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
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
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: Color(0xFF64748B),
            letterSpacing: 1.0,
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
    return Center(
      child: TextButton.icon(
        onPressed: () => setState(() => _visibleCount += _pageSize),
        icon: const Icon(Icons.expand_more, size: 18),
        label: Text(l10n.historyShowMore(remaining)),
      ),
    );
  }

  Widget _buildGoodJobBanner(AppLocalizations l10n, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFEF3C7),
            radius: 16,
            child: Icon(
              Icons.accessibility_new,
              color: Color(0xFFF59E0B),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD97706),
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
    // We only plot records that have Body Fat
    final validRecords = records
        .where((r) => r.bodyFatPercent != null)
        .toList();
    if (validRecords.isEmpty) return const SizedBox.shrink();

    final recentRecords = validRecords.length > 6
        ? validRecords.sublist(validRecords.length - 6)
        : validRecords;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.compositionBodyFat.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filterLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
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
                rangeAnnotations: bandRangeAnnotations('BODY_FAT',
                    minY: minDisplay, maxY: maxDisplay),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < recentRecords.length) {
                          final format = DateFormat.MMM();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              format.format(recentRecords[index].date),
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
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
                    color: const Color(0xFFF59E0B),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFF59E0B),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
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

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'body_composition_history.pdf',
    );
  }

  Future<void> _exportCsv(
    List<BodyCompositionRecord> records,
    AppLocalizations l10n,
  ) async {
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
    await SharePlus.instance.share(
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
    );
  }

  /// Red background revealed when swiping a history item left to delete it.
  Widget _deleteSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  /// Asks the user to confirm deletion, then deletes the record. Always returns
  /// false so the [Dismissible] never self-removes: the repository listener
  /// re-fetches the list and drops the row, which is what updates the UI.
  Future<bool> _confirmDelete(AppLocalizations l10n, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteRecordTitle),
        content: Text(l10n.deleteRecordBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.deleteRecordConfirm,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BodyCompositionRepository.instance.delete(id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.recordDeleted),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    return false;
  }

  /// Línea compacta con los demás valores del registro (músculo %/kg, visceral,
  /// edad metabólica, TMB) — visible p. ej. en la historia importada del legacy.
  String? _secondaryLine(BodyCompositionRecord r) {
    final parts = <String>[
      if (r.musclePct != null) 'Músculo ${r.musclePct}%',
      if (r.musclePct == null && r.muscleMassKg != null)
        'Músculo ${r.muscleMassKg}kg',
      if (r.visceralFatLevel != null) 'Visceral ${r.visceralFatLevel}',
      if (r.metabolicAge != null) 'Edad ${r.metabolicAge}',
      if (r.bmrKcal != null) '${r.bmrKcal} kcal',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _buildHistoryItem(
    BodyCompositionRecord record,
    AppLocalizations l10n,
  ) {
    final double defaultFat = record.bodyFatPercent ?? 0.0;
    final FatCategory fatCat = FatCategory.of(defaultFat);
    final String statusLabel = fatCat.label(l10n);
    final Color statusColor = fatCat.color;
    final dateFormat = DateFormat(
      'dd MMM yyyy',
    ).format(record.date).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '% Grasa',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_secondaryLine(record) != null) ...[
                const SizedBox(height: 4),
                Text(
                  _secondaryLine(record)!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
          if (record.bodyFatPercent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
