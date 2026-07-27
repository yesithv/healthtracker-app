import 'package:flutter/painting.dart' show Color, HSLColor;

import 'tokens/clinical_palette.dart';
import 'tokens/content_palette.dart';
import 'tokens/metric_palette.dart';

/// El CONTRATO SEMÁNTICO: las reglas que todo tema debe cumplir para poder
/// entrar en el catálogo.
///
/// La promesa al usuario es que puede cambiar el aspecto de la app sin que el
/// significado de los colores cambie debajo de sus pies: si aprendió que el
/// ámbar pide atención y el rojo alarma, eso sigue siendo verdad en cualquier
/// tema. Y que en ningún tema un dato de salud quede ilegible.
///
/// Aquí esa promesa se escribe como aritmética comprobable, y
/// `test/core/theme/semantic_contract_test.dart` la ejecuta contra TODOS los
/// temas del catálogo. Añadir un tema que la incumpla rompe el build: es la
/// diferencia entre «tuvimos cuidado» y «no puede pasar».
class SemanticContract {
  const SemanticContract._();

  /// Contraste mínimo para texto pequeño (WCAG 2.1 AA, criterio 1.4.3).
  /// Las insignias de estado son texto de 10–12 px: entran aquí, no en el
  /// umbral relajado de 3:1 que sólo aplica a texto grande y a gráficos.
  static const double minTextContrast = 4.5;

  /// Contraste mínimo para elementos no textuales: trazos de gráfica, iconos,
  /// bordes con carga informativa (WCAG 2.1 AA, criterio 1.4.11).
  static const double minGraphicContrast = 3.0;

  /// Saturación mínima de un color con carga semántica. Impide que un tema
  /// «cumpla» el contraste apagando todo a gris y borrando la distinción entre
  /// estados, que es justo lo que no queremos.
  static const double minSemanticSaturation = 0.15;

  /// Separación mínima de matiz, en grados, entre dos familias de indicador.
  /// Por debajo de esto el usuario dejaría de distinguirlas de un vistazo.
  static const double minFamilyHueSeparation = 20.0;

  /// Franja de matiz admisible para cada estado clínico. Es la regla que
  /// mantiene el significado estable entre temas: un tema puede elegir QUÉ
  /// verde usa para «óptimo», no puede decidir que «óptimo» sea morado.
  static const Map<ClinicalStatus, HueBand> statusHues = {
    ClinicalStatus.info: HueBand(185, 265), // frío: azul / pizarra
    ClinicalStatus.optimal: HueBand(90, 175), // verde
    ClinicalStatus.caution: HueBand(20, 70), // ámbar / ocre
    ClinicalStatus.alert: HueBand(345, 20), // rojo (cruza el origen)
    // `neutral` no afirma nada clínico: queda exento a propósito.
  };

  /// Franja de matiz admisible para cada familia de indicador.
  static const Map<MetricFamily, HueBand> familyHues = {
    MetricFamily.vitals: HueBand(340, 20), // rojo — corazón, tensión
    MetricFamily.anthropometry: HueBand(20, 70), // ámbar — medida corporal
    MetricFamily.lipids: HueBand(150, 200), // verde azulado — laboratorio
    MetricFamily.bodyComposition: HueBand(200, 265), // índigo — estructura
  };

  /// Franja de matiz admisible para cada categoría editorial de «Descubre».
  ///
  /// Misma lógica que las familias: el usuario aprende a reconocer la sección
  /// por su color, así que un tema puede apagar el naranja de «deporte» pero no
  /// convertirlo en azul.
  static const Map<ContentCategory, HueBand> contentHues = {
    ContentCategory.heart: HueBand(340, 20), // rojo
    ContentCategory.nutrition: HueBand(90, 175), // verde
    ContentCategory.emotional: HueBand(265, 320), // violeta
    ContentCategory.sports: HueBand(15, 50), // naranja
    ContentCategory.sleep: HueBand(220, 265), // índigo
    ContentCategory.daily: HueBand(160, 200), // turquesa
  };

  /// Razón de contraste WCAG 2.1 entre dos colores opacos.
  ///
  /// Devuelve un valor en [1, 21]: 1 es indistinguible, 21 es negro sobre
  /// blanco. Usa la luminancia relativa ya linealizada que expone
  /// [Color.computeLuminance].
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Matiz de [color] en grados [0, 360).
  static double hueOf(Color color) => HSLColor.fromColor(color).hue;

  /// Saturación de [color] en [0, 1].
  static double saturationOf(Color color) =>
      HSLColor.fromColor(color).saturation;

  /// Distancia angular más corta entre dos matices, en grados [0, 180].
  static double hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
}

/// Una franja de matiz, en grados. Puede cruzar el origen —el rojo vive a
/// caballo entre 345° y 20°—, de ahí que [contains] no sea una comparación
/// ingenua.
class HueBand {
  const HueBand(this.start, this.end);

  final double start;
  final double end;

  bool get wrapsOrigin => start > end;

  bool contains(double hue) {
    final h = hue % 360;
    return wrapsOrigin ? (h >= start || h <= end) : (h >= start && h <= end);
  }

  @override
  String toString() =>
      '${start.toStringAsFixed(0)}°–${end.toStringAsFixed(0)}°';
}
