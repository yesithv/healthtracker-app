import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Impide que vuelva a colarse un estilo ANCLADO A UN TEMA.
///
/// **El defecto que motiva este archivo.** El realce de la pestaña activa se
/// calculaba con `Color.lerp(card, brand, 0.08)`. Ese 8 % fijo aparta el blanco
/// MÁS cuanto más oscura sea la marca, así que dibujaba un realce claro con el
/// azul de «Pulso Clínico» y algo casi invisible con el salvia de «Consulta
/// Serena» — y con una marca aún más clara habría desaparecido del todo.
///
/// El patrón se repetía: media app escribía su propia sombra con un
/// `BoxShadow(...)` a mano, y un `BoxShadow` a mano no sabe si el tema levanta
/// las cosas del lienzo o las deja planas. «Consulta Serena» no tiene ni una
/// sombra en sus tarjetas y sí las tenía sueltas por dentro.
///
/// Lo que estas pruebas defienden es una regla: **un efecto visual no puede
/// nacer de una cuenta hecha en la pantalla; tiene que venir del tema**, que es
/// el único que sabe si es plano o elevado, claro u oscuro. Los valores
/// concretos los verifica `semantic_contract_test.dart`; aquí se verifica que
/// nadie se salte el mecanismo.
void main() {
  /// Archivos de interfaz: todo `lib` menos la definición de los propios temas
  /// —que es justo donde SÍ se escriben sombras y colores— y lo generado.
  List<File> uiFiles() {
    return Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('/core/theme/'))
        .where((f) => !f.path.contains('/generated/'))
        .toList();
  }

  test('ninguna pantalla escribe una sombra a mano', () {
    final offenders = <String>[];
    for (final f in uiFiles()) {
      // El electro del arranque es la excepción declarada: sus dos resplandores
      // solo existen dentro de `if (monitorBezel)`, o sea que el propio tema ya
      // decidió que ahí hay cromo de instrumental.
      if (f.path.endsWith('ecg_trace.dart')) continue;

      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('BoxShadow(')) continue;
        if (lines[i].trimLeft().startsWith('//')) continue;
        offenders.add(
          '${f.path}:${i + 1} — usa `surfaces.cardShadow` para la elevación '
          'normal, o `surfaces.glow(color)` para un halo de acento. Los dos '
          'devuelven vacío en los temas planos.',
        );
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('nadie improvisa el realce de «esto está elegido»', () {
    // `Color.lerp(card, brand, x)` y `brand.withValues(alpha: x)` eran las dos
    // formas de escribirlo a mano. Ahora hay token: `surfaces.selection`.
    final byHand = RegExp(
      r'Color\.lerp\(\s*surfaces\.(card|canvas)\s*,\s*surfaces\.brand'
      r'|surfaces\.brand\.withValues\(\s*alpha: 0\.0[0-9]',
    );
    final offenders = <String>[];
    for (final f in uiFiles()) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (byHand.hasMatch(lines[i])) {
          offenders.add(
            '${f.path}:${i + 1} — usa `surfaces.selection` y '
            '`surfaces.onSelection`. Un porcentaje fijo de mezcla con la marca '
            'da un escalón distinto en cada tema.',
          );
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('ninguna pantalla pregunta qué tema está activo', () {
    // Si el comportamiento debe cambiar entre temas, eso es un token —así
    // nacieron `badgeIdiom` y `monitorBezel`—, no un `if`.
    final asking = RegExp(r'AppThemeId\.\w+\s*(==|!=)|themeId\s*(==|!=)');
    final offenders = <String>[];
    for (final f in uiFiles()) {
      // El provider ES quien traduce la preferencia guardada a un identificador.
      if (f.path.endsWith('theme_provider.dart')) continue;
      // El selector muestra los temas: comparar cuál está elegido es su trabajo.
      if (f.path.contains('/theming/')) continue;

      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (asking.hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Estas líneas ramifican según el tema activo. Si el acabado debe '
          'cambiar, el que tiene que saberlo es el tema:\n'
          '${offenders.join('\n')}',
    );
  });
}
