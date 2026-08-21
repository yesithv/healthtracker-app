import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/dashboard/presentation/widgets/appointments_card.dart';
import 'package:myvitals_healthtracker_app/features/dashboard/presentation/widgets/dashboard_summary_row.dart';
import 'package:myvitals_healthtracker_app/features/dashboard/presentation/widgets/medications_summary_card.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';

/// Prueba de regresión de la fila de minicards (Medicamentos + Citas) del fondo
/// del Dashboard.
///
/// Monta [DashboardSummaryRow] **dentro de un `ListView`** —es decir, con altura
/// entrante NO acotada, igual que en la pantalla real— y a varias anchuras de
/// móvil y escalas de texto. Antes la fila usaba `AspectRatio` de alto fijo, que
/// a anchos reales dejaba el contenido desbordado fuera del recuadro decorado
/// (las tarjetas se veían «sin borde») y añadía scroll fantasma. La prueba fija
/// el contrato del arreglo con [IntrinsicHeight]:
///   1. no se lanza ningún overflow, y
///   2. las dos tarjetas comparten un alto FINITO dirigido por el contenido.
/// La prueba de card aislada (`appointments_card_test`) no cubría esto porque
/// montaba la tarjeta en un `SizedBox` de alto fijo, nunca en el contexto real.

class _NoopMedScheduler extends MedicationScheduler {
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

class _NoopApptScheduler extends AppointmentScheduler {
  @override
  Future<void> rescheduleAll({
    required List<Appointment> appointments,
    DateTime? now,
    int horizonDays = AppointmentScheduler.defaultHorizonDays,
    AppointmentTextBuilder? scheduledText,
    AppointmentTextBuilder? toBookText,
    AppointmentTextBuilder? overdueText,
  }) async {}
}

Widget _host({
  required MedicationsController meds,
  required AppointmentsController appts,
  required AppThemeId themeId,
  required double width,
  required double textScale,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MedicationsController>.value(value: meds),
      ChangeNotifierProvider<AppointmentsController>.value(value: appts),
    ],
    child: MaterialApp(
      theme: AppThemeCatalog.themeOf(themeId),
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          // Escala de texto para provocar el peor caso de altura de contenido.
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                // Alto amplio y `ListView` para reproducir la altura entrante NO
                // acotada de la pantalla real (donde la fila vive en un ListView).
                height: 900,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [DashboardSummaryRow()],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await MedicationRepository.instance.clearAll();
    await MedicationDoseRepository.instance.clearAll();
    await MedicationLogRepository.instance.clearAll();
    await AppointmentRepository.instance.clearAll();
  });

  // Peor caso de contenido en ambas tarjetas: Medicamentos con toma pendiente
  // hoy (héroe + posible chip) y Citas con una cita vencida (héroe + chip
  // «Vencida»). Es el estado más alto, el que antes desbordaba el recuadro.
  Future<void> seed(
    WidgetTester tester,
    MedicationsController meds,
    AppointmentsController appts,
  ) async {
    await tester.runAsync(() async {
      final med = Medication(
        name: 'Metformina',
        doseQuantity: 1,
        frequencyType: FrequencyType.daily,
        startDate: DateTime(2020, 1, 1),
      );
      await meds.addMedication(med, [
        MedicationDose(medicationId: med.id, hour: 20, minute: 30),
      ]);
      await appts.addToBook(
        title: 'Perfil lipídico completo',
        dueToBookOn: DateTime.now().subtract(const Duration(days: 8)),
      );
    });
  }

  // Anchos representativos de móvil (el ancho útil de cada tarjeta es la mitad,
  // menos el separador) y escalas de texto normal/aumentada.
  const widths = <double>[320, 360, 390];
  const scales = <double>[1.0, 1.3];
  const themes = <AppThemeId>[
    AppThemeId.pulsoClinico,
    AppThemeId.consultaSerena,
  ];

  for (final themeId in themes) {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets(
          'sin overflow y alto gemelo finito · $themeId · ${width.toInt()}px · x$scale',
          (tester) async {
            final meds = MedicationsController(scheduler: _NoopMedScheduler());
            final appts = AppointmentsController(
              scheduler: _NoopApptScheduler(),
            );
            addTearDown(meds.dispose);
            addTearDown(appts.dispose);

            await seed(tester, meds, appts);

            await tester.pumpWidget(
              _host(
                meds: meds,
                appts: appts,
                themeId: themeId,
                width: width,
                textScale: scale,
              ),
            );
            await tester.pump();

            // 1) Ningún RenderFlex desbordado ni otra excepción de layout.
            expect(
              tester.takeException(),
              isNull,
              reason: 'layout overflow a $width px, x$scale, $themeId',
            );

            // 2) Las dos tarjetas existen y comparten un alto finito, dirigido por
            //    el contenido (IntrinsicHeight): ni cero, ni desmesurado.
            final medSize = tester.getSize(find.byType(MedicationsSummaryCard));
            final apptSize = tester.getSize(find.byType(AppointmentsCard));

            expect(medSize.height, greaterThan(0));
            expect(medSize.height.isFinite, isTrue);
            expect(
              medSize.height,
              lessThan(600),
              reason: 'alto desmesurado sugiere extensión fantasma',
            );
            // Gemelas: mismo alto exacto por IntrinsicHeight + stretch.
            expect(
              apptSize.height,
              moreOrLessEquals(medSize.height, epsilon: 0.5),
            );
          },
        );
      }
    }
  }
}
