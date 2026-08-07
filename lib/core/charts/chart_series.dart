import 'package:intl/intl.dart';

/// Utilidades puras para las gráficas de tendencia del historial.
///
/// Viven APARTE de los widgets —Dart puro, sin `BuildContext` ni Flutter— por la
/// misma razón que `demo_dataset.dart`: lo que no toca el árbol de widgets se
/// puede comprobar entero desde una prueba unitaria (`test/core/charts/`).
///
/// Nacieron para arreglar un bug real: las cuatro pestañas de historial recortaban
/// la gráfica a los ÚLTIMOS 6 registros con `sublist(length - 6)`, ignorando el
/// filtro de tiempo (7 días / 30 días / 6 meses / Siempre). Elegir «Siempre» daba
/// la misma línea plana reciente que «6 meses». Aquí vive el muestreo que deja a la
/// gráfica dibujar todo el rango filtrado sin ahogarse en miles de puntos.
library;

/// Reduce [items] a como mucho [maxPoints] elementos con un muestreo UNIFORME que
/// SIEMPRE conserva el primero y el último. Así una serie de dos años entra en la
/// gráfica sin perder ni el arranque ni el valor más reciente —los dos extremos que
/// cuentan la mejora— y sin dibujar un punto por medición.
///
/// Espera [items] ya ordenado (normalmente ascendente por fecha). Si hay
/// [maxPoints] o menos, se devuelve tal cual. [maxPoints] debe ser >= 2.
List<T> downsample<T>(List<T> items, {int maxPoints = 24}) {
  assert(maxPoints >= 2, 'maxPoints debe ser al menos 2');
  final n = items.length;
  if (n <= maxPoints) return List<T>.from(items);

  final result = <T>[];
  // Repartimos maxPoints posiciones entre [0, n-1] de forma pareja. La fórmula
  // garantiza que el primer índice sea 0 y el último n-1.
  for (var i = 0; i < maxPoints; i++) {
    final idx = (i * (n - 1) / (maxPoints - 1)).round();
    result.add(items[idx]);
  }
  return result;
}

/// Cada cuántos puntos toca dibujar una etiqueta en el eje X para no amontonarlas.
///
/// Con [count] puntos y un tope de [maxLabels] etiquetas, devuelve el paso: p. ej.
/// 24 puntos con tope 6 → una etiqueta cada 5. Nunca menos de 1.
int axisLabelStep(int count, {int maxLabels = 6}) {
  if (count <= maxLabels) return 1;
  return (count / maxLabels).ceil();
}

/// Formato de fecha para el eje X según el ABANICO que cubre la serie.
///
/// El bug viejo usaba `DateFormat.MMM()` (solo el mes) para todo: seis puntos en dos
/// semanas se leían «Ago Ago Ago…», y dos puntos a un año de distancia eran
/// indistinguibles porque no había año. Aquí el formato se adapta:
///   - hasta ~35 días  → día y mes  («5 ago»)
///   - hasta ~1 año    → mes        («ago»)
///   - más de un año   → mes y año  («ago 24»)
DateFormat axisDateFormat(DateTime first, DateTime last, [String? locale]) {
  final spanDays = last.difference(first).inDays.abs();
  if (spanDays <= 35) return DateFormat.MMMd(locale);
  if (spanDays <= 366) return DateFormat.MMM(locale);
  return DateFormat('MMM yy', locale);
}
