import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/widgets/clinic_data_freshness.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Hasta cuándo llega la historia que vino de la clínica.
///
/// **Lo que arregla.** El sincronizador que trae esa historia puede pararse —se comprobó
/// apagando la ACL: los cuatro pacientes fallaron y nada lo dijo— y hasta ahora la app enseñaba
/// exactamente los mismos números en los dos casos. Ver datos de hace una semana creyendo que son
/// de hoy es la versión numérica de lo que la Fase 7 quitó de los textos legales.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // El perfil busca la foto en el directorio de documentos y en una prueba no hay plugin
    // nativo que conteste: sin este mock la llamada no vuelve nunca y la prueba se cuelga sin
    // decir nada. Mismo tropiezo que en la Fase 5, mismo remedio.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          Directory.systemTemp.createTempSync('clinic_freshness').path,
    );
  });

  Future<void> pump(WidgetTester tester, DateTime? syncedAt) async {
    final profile = UserProfileProvider();
    await profile.setClinicDataSyncedAt(syncedAt);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: MaterialApp(
          theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const Scaffold(body: ClinicDataFreshness()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('quien no viene de la clínica no ve nada', (tester) async {
    // No es que esté al día: es que no hay ninguna historia traída que fechar. Enseñar una línea
    // vacía o un «sin datos» sería inventarle a esta persona una relación que no tiene.
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('con los datos recientes dice la fecha, sin alarmar', (
    tester,
  ) async {
    await pump(tester, DateTime.now().subtract(const Duration(hours: 3)));

    expect(find.textContaining('actualizados al'), findsOneWidget);
    expect(find.textContaining('no llega nada nuevo'), findsNothing);
  });

  testWidgets('pasados dos días avisa y dice cuántos', (tester) async {
    // Un día de retraso entra dentro de lo normal —la corrida del servidor es diaria y puede
    // llegar tarde—; dos ya no, y decir el número evita que «desactualizado» se lea como
    // «roto para siempre».
    await pump(tester, DateTime.now().subtract(const Duration(days: 5)));

    expect(find.textContaining('hace 5 días'), findsOneWidget);
  });

  testWidgets('justo en el límite todavía no avisa', (tester) async {
    await pump(tester, DateTime.now().subtract(const Duration(hours: 25)));

    expect(find.textContaining('no llega nada nuevo'), findsNothing);
  });

  test('la fecha sobrevive a reabrir la app', () async {
    // Es cuando más importa: sin conexión no se puede refrescar, y es justo entonces cuando hay
    // que saber que lo que se está mirando puede no ser lo último.
    //
    // Va como `test` y no como `testWidgets` a propósito: comprueba persistencia, no pintado, y
    // dentro de `testWidgets` un `await` sobre el canal nativo de las preferencias no se resuelve
    // —el reloj es falso— y la prueba se queda colgada sin decir por qué.
    final syncedAt = DateTime.now().subtract(const Duration(days: 4));
    SharedPreferences.setMockInitialValues({
      'clinic_data_synced_at': syncedAt.toIso8601String(),
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          Directory.systemTemp.createTempSync('clinic_freshness').path,
    );

    final reopened = UserProfileProvider();
    await reopened.ready;

    expect(reopened.clinicDataSyncedAt, isNotNull);
    expect(reopened.clinicDataAgeDays, 4);
  });
}
