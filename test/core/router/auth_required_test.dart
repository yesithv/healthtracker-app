import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/router/app_router.dart';

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
      expect(allPaths(), contains('/intro'));
    });

    test('la portada antigua ya no está enrutada', () {
      // `/welcome` ofrecía «explorar sin cuenta»: dejarla enrutada mantendría
      // viva una puerta trasera al modo local.
      expect(
        allPaths(),
        isNot(contains('/welcome')),
        reason: 'La portada antigua permitía entrar sin cuenta',
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
    Iterable<File> sources() => Directory('lib')
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
}
