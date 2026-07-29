import 'package:fl_chart/fl_chart.dart';

import '../theme/tokens/clinical_palette.dart';
import 'reference_ranges_store.dart';

/// Código de banda del servidor → estado clínico.
///
/// Antes este archivo tenía su propia tabla de hexadecimales «la MISMA paleta
/// semántica de los clasificadores», copiada a mano. Copiada quiere decir que
/// podía dejar de ser la misma sin que nada avisara: el fondo de la gráfica
/// pintaba un ámbar y la insignia de al lado otro. Ahora traduce a
/// [ClinicalStatus] y el color lo resuelve el tema, que es el único que lo sabe.
const Map<String, ClinicalStatus> _bandStatus = {
  'VERY_LOW': ClinicalStatus.info,
  'LOW': ClinicalStatus.info,
  'UNDERWEIGHT': ClinicalStatus.info,
  'NEAR_OPTIMAL': ClinicalStatus.info,
  'NORMAL': ClinicalStatus.optimal,
  'OPTIMAL': ClinicalStatus.optimal,
  'PROTECTIVE': ClinicalStatus.optimal,
  'DESIRABLE': ClinicalStatus.optimal,
  'ELEVATED': ClinicalStatus.caution,
  'BORDERLINE': ClinicalStatus.caution,
  'OVERWEIGHT': ClinicalStatus.caution,
  'PREDIABETES': ClinicalStatus.caution,
  'HIGH': ClinicalStatus.caution,
  'VERY_HIGH': ClinicalStatus.alert,
  'OBESE': ClinicalStatus.alert,
};

/// Zonas de color de fondo para la gráfica de [indicatorCode]: las bandas del
/// servidor (dispositivo/sexo/edad del paciente, [ReferenceRangesStore]) recortadas
/// al dominio visible [minY, maxY]. Sin rangos aplicables → sin zonas (gráfica
/// normal): la interpretación NUNCA se inventa en el cliente.
///
/// [palette] es la del tema activo (`Theme.of(context).clinical`). Se pide en
/// vez de leerse de un `BuildContext` para que esta función siga sin depender
/// del árbol de widgets.
RangeAnnotations bandRangeAnnotations(
  String indicatorCode, {
  required ClinicalPalette palette,
  required double minY,
  required double maxY,
  double opacity = 0.08,
}) {
  final bands = ReferenceRangesStore.instance.bandsOf(indicatorCode);
  final zones = <HorizontalRangeAnnotation>[];
  for (final b in bands) {
    final lo = b.minValue < minY ? minY : b.minValue;
    final hi = b.maxValue > maxY ? maxY : b.maxValue;
    if (hi <= lo) continue;
    // Banda desconocida → `neutral`, que es gris en todos los temas: se ve que
    // hay una zona sin afirmar nada clínico sobre ella.
    final status =
        _bandStatus[b.bandCode.toUpperCase()] ?? ClinicalStatus.neutral;
    zones.add(
      HorizontalRangeAnnotation(
        y1: lo,
        y2: hi,
        color: palette.tone(status).accent.withValues(alpha: opacity),
      ),
    );
  }
  return RangeAnnotations(horizontalRangeAnnotations: zones);
}
