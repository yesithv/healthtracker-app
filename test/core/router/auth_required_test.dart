import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/router/app_router.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';

/// Fija el invariante de acceso: **la cuenta es obligatoria**.
///
/// La app dejó de tener modo local («explorar sin cuenta»), y eso es fácil de
/// reabrir sin darse cuenta —basta un botón nuevo que mande al asistente sin
/// pasar por el registro, o volver a enrutar la portada antigua—. Estas pruebas
/// son la red: si alguien reintroduce un camino de entrada sin sesión, fallan.
void main() {
  /// Rutas declaradas en el router, aplanando las anidadas del shell.
  List<String> allPaths() {
    final paths = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) paths.add(r.path);
        walk(r.routes);
      }
    }

    walk(AppRouter.router.configuration.routes);
    return paths;
  }

  group('acceso con cuenta obligatoria ·', () {
    test('la portada del flujo está enrutada', () {
      expect(allPaths(), contains('/welcome'));
    });

    test('la portada anterior ya no está enrutada', () {
      // `/intro` fue el nombre intermedio de la portada; el flujo actual entra
      // por `/welcome` (misma garantía: cuenta obligatoria, sin modo local).
      // Dejar `/intro` enrutada mantendría viva una portada muerta.
      expect(
        allPaths(),
        isNot(contains('/intro')),
        reason: 'La portada anterior ya no debe estar enrutada',
      );
    });

    test('el arranque y el panel siguen enrutados', () {
      expect(allPaths(), containsAll(['/', '/splash', '/dashboard']));
    });

    test('el selector de temas está en la raíz y en Perfil', () {
      expect(allPaths(), containsAll(['/', '/profile/theme']));
    });
  });

  group('sin rastro del modo local ·', () {
    /// Todos los .dart de `lib`, excluyendo lo generado por gen_l10n.
    Iterable<File> sources() =>
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !f.path.contains('l10n/generated'));

    test('ninguna pantalla navega al asistente en modo sin cuenta', () {
      final offenders = <String>[];
      for (final f in sources()) {
        final src = f.readAsStringSync();
        // Se busca en el CÓDIGO, no en los comentarios: la historia del cambio
        // sí puede nombrar el modo que se eliminó.
        final code = src
            .split('\n')
            .where((l) => !l.trimLeft().startsWith('//'))
            .where((l) => !l.trimLeft().startsWith('///'))
            .join('\n');
        if (code.contains('mode=offline')) offenders.add(f.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Estas pantallas reabren la entrada sin cuenta: $offenders',
      );
    });

    test('el asistente de alta no admite un modo que evite el registro', () {
      final shell = File(
        'lib/features/onboarding/presentation/screens/onboarding_shell.dart',
      ).readAsStringSync();
      expect(
        shell.contains('createAccount'),
        isFalse,
        reason:
            'La bandera createAccount permitía terminar el asistente sin crear '
            'la cuenta; el alta debe registrar siempre.',
      );
    });
  });

  group('la demo es la única vía nueva sin cuenta ·', () {
    // La demostración es la ÚNICA entrada sin cuenta que se admite, y bajo
    // condiciones estrictas: datos ficticios, marcados, en una base aparte y
    // borrados al salir (ver DemoSession). Estas pruebas fijan que la portada
    // entre por esa puerta y no por otra improvisada.
    final intro = File(
      'lib/features/welcome/presentation/screens/welcome_screen.dart',
    ).readAsStringSync();

    /// El código de la portada sin comentarios: el «por qué» del cambio sí puede
    /// nombrar caminos que no existen.
    String introCode() => intro
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .where((l) => !l.trimLeft().startsWith('///'))
        .join('\n');

    test('la portada entra a la demo por la vía sancionada', () {
      expect(
        introCode().contains('enterDemo('),
        isTrue,
        reason:
            'La demo debe entrarse por enterDemo(), que copia las preferencias '
            'y cambia a la base desechable; no por un atajo.',
      );
    });

    test('la portada no salta al panel por su cuenta', () {
      // Un `go('/dashboard')` en la portada sería una puerta trasera al panel
      // sin pasar por la sesión ni por la demo. El único que enruta al panel es
      // enterDemo (tras activar la demo) o el arranque con sesión.
      expect(
        introCode().contains("'/dashboard'"),
        isFalse,
        reason: 'La portada no debe navegar directamente al panel.',
      );
    });

    test('la demo arranca inactiva: nadie entra sin pedirlo', () {
      expect(DemoSession.instance.isActive, isFalse);
    });
  });
}
