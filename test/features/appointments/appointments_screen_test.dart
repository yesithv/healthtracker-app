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
import 'package:myvitals_healthtracker_app/features/appointments/presentation/screens/appointments_screen.dart';

/// Planificador noop: evita tocar notificaciones/SharedPreferences en el test.
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

Widget _host(AppointmentsController controller) {
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
      home: const AppointmentsScreen(),
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

  testWidgets(
    'una cita por sacar vencida enciende el semáforo rojo y la acción '
    'de editar',
    (tester) async {
      final controller = AppointmentsController(scheduler: _NoopScheduler());
      await tester.runAsync(() async {
        await controller.addToBook(
          title: 'Perfil lipídico',
          dueToBookOn: DateTime.now().subtract(const Duration(days: 10)),
        );
      });

      await tester.pumpWidget(_host(controller));
      await tester.pump();

      // Semáforo en rojo (hay una vencida).
      expect(find.text('Requiere atención'), findsOneWidget);
      // Chip de vencida en la tarjeta.
      expect(find.text('Vencida'), findsOneWidget);
      // La acción de editar está disponible sobre la cita abierta.
      expect(find.text('Editar'), findsOneWidget);

      controller.dispose();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  testWidgets(
    'sin nada abierto pero con historial, el semáforo está en verde',
    (tester) async {
      final controller = AppointmentsController(scheduler: _NoopScheduler());
      await tester.runAsync(() async {
        final appt = await controller.addScheduled(
          title: 'Cardiología',
          scheduledAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        await controller.markAttended(appt);
      });

      await tester.pumpWidget(_host(controller));
      await tester.pump();

      expect(find.text('Todo al día'), findsOneWidget);
      // Con historial, no debería aparecer el estado vacío ni el rojo.
      expect(find.text('Requiere atención'), findsNothing);

      controller.dispose();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
