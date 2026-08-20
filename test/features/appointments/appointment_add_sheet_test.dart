import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/widgets/appointment_add_sheet.dart';

class _NoopScheduler extends AppointmentScheduler {
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

Widget _host(AppointmentsController controller, {Appointment? existing}) {
  return ChangeNotifierProvider<AppointmentsController>.value(
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
      home: Scaffold(body: AppointmentAddSheet(existing: existing)),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppointmentRepository.instance.clearAll();
  });

  testWidgets('el toggle de control periódico revela el selector de cada N meses',
      (tester) async {
    final controller = AppointmentsController(scheduler: _NoopScheduler());
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    // Antes de activar la recurrencia, el selector no está.
    expect(find.text('Cada cuánto'), findsNothing);
    expect(find.text('Cada 3 meses'), findsNothing);

    // El formulario vive en un scroll: hay que traer el toggle a la vista antes
    // de tocarlo (si no, el tap cae fuera de pantalla).
    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();

    // Activa el toggle de control periódico.
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // Aparecen el selector de periodicidad y sus opciones.
    expect(find.text('Cada cuánto'), findsOneWidget);
    expect(find.text('Cada 3 meses'), findsOneWidget);
    expect(find.text('Cada 6 meses'), findsOneWidget);

    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('en modo edición precarga los campos de la cita', (tester) async {
    final controller = AppointmentsController(scheduler: _NoopScheduler());
    final existing = Appointment(
      title: 'Control endocrino',
      specialty: 'Endocrinología',
      status: AppointmentStatus.toBook,
      dueToBookOn: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(_host(controller, existing: existing));
    await tester.pump();

    // Título de edición y campos precargados.
    expect(find.text('Editar cita'), findsOneWidget);
    expect(find.text('Control endocrino'), findsOneWidget);
    expect(find.text('Endocrinología'), findsOneWidget);

    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
