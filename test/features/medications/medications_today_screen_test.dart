import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/screens/medications_today_screen.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/widgets/medication_dose_tile.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/view_models/med_view_models.dart';

/// Primer test de widget del módulo (y de la app): comprueba que la pantalla
/// «Hoy» pinta la toma pendiente del día y que, al registrarse a través del
/// controlador, la pantalla se reconstruye y refleja el nuevo estado. Establece
/// el patrón de test de widget para las siguientes pantallas.
class _NoopScheduler extends MedicationScheduler {
  @override
  Future<void> rescheduleAll({
    required List<Medication> medications,
    required Map<String, List<MedicationDose>> dosesByMedication,
    DateTime? now,
    int horizonDays = MedicationScheduler.defaultHorizonDays,
    bool Function(String medicationId, DateTime scheduledAt)? isAlreadyLogged,
    DoseTextBuilder? doseText,
    InventoryTextBuilder? inventoryText,
  }) async {}
}

Widget _host(MedicationsController controller) {
  return ChangeNotifierProvider<MedicationsController>.value(
    value: controller,
    child: MaterialApp(
      theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MedicationsTodayScreen(),
    ),
  );
}

MedicationDoseTile _tile(WidgetTester tester) =>
    tester.widget<MedicationDoseTile>(find.byType(MedicationDoseTile));

void main() {
  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-medications-today-screen.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await MedicationRepository.instance.clearAll();
    await MedicationDoseRepository.instance.clearAll();
    await MedicationLogRepository.instance.clearAll();
  });

  testWidgets(
    "renders today's pending dose and reflects registering it",
    (tester) async {
      final controller = MedicationsController(scheduler: _NoopScheduler());
      // Pauta diaria: hay una toma esperada hoy sea cual sea la fecha del reloj.
      final med = Medication(
        name: 'Vytorin',
        doseQuantity: 2,
        frequencyType: FrequencyType.daily,
        startDate: DateTime(2020, 1, 1),
      );
      // Las escrituras a SQLite (ffi) son E/S real. En un test de widget el cuerpo
      // corre bajo el reloj FALSO de `testWidgets`, que no avanza los
      // temporizadores/E-S reales, así que un `await` directo sobre la base se
      // colgaría. `tester.runAsync` ejecuta la E/S en la zona async real.
      await tester.runAsync(() async {
        await controller.addMedication(med, [
          MedicationDose(medicationId: med.id, hour: 8, minute: 0),
        ]);
      });

      // Un `pump()` (no `pumpAndSettle`): la pantalla no tiene animaciones que
      // asentar; solo hace falta un frame para pintar los datos ya sembrados.
      await tester.pumpWidget(_host(controller));
      await tester.pump();

      // La toma aparece, pendiente.
      expect(find.text('Vytorin'), findsOneWidget);
      expect(_tile(tester).dose.state, DoseState.pending);

      // Registrarla como tomada por el controlador reconstruye la pantalla (de
      // nuevo con `runAsync` por la escritura a la base).
      final entry = controller.entriesForDay(DateTime.now()).first;
      await tester.runAsync(() async {
        await controller.logDose(entry, taken: true);
      });
      await tester.pump();

      expect(find.text('Vytorin'), findsOneWidget);
      expect(_tile(tester).dose.state, DoseState.taken);

      controller.dispose();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
