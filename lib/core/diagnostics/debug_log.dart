import 'package:flutter/foundation.dart';

/// Deja rastro de un error ATRAPADO Y MANEJADO, solo en depuración.
///
/// Buena parte de los `catch` de la app degradan con elegancia —fallback a la
/// semilla empaquetada, a lo guardado en local, a un valor por defecto— y por
/// diseño NO deben molestar al usuario ni cortar el flujo. Pero tragarse el
/// error sin dejar rastro esconde, en desarrollo, por qué se tomó ese camino de
/// respaldo: un feed que no parsea, una sincronización que no sube, una foto que
/// no se lee. Esta función deja ese rastro con una etiqueta de contexto.
///
/// Coste cero en producción: el cuerpo vive bajo `kDebugMode`, una constante de
/// compilación, así que en release el árbol se elimina entero (tree-shaking) y
/// no queda ni la llamada ni el texto. Úsese SOLO para errores que ya se
/// manejan; los que deben cortar el flujo se relanzan, no se registran aquí.
void debugLogError(String context, Object error, [StackTrace? stackTrace]) {
  if (kDebugMode) {
    debugPrint('[$context] $error');
  }
}
