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
import 'package:myvitals_healthtracker_app/features/dashboard/presentation/widgets/appointments_card.dart';

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
      // El `Expanded` interno de la tarjeta necesita un alto acotado.
      home: const Scaffold(
        body: Center(
          child: SizedBox(width: 200, height: 240, child: AppointmentsCard()),
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
    await AppointmentRepository.instance.clearAll();
  });

  testWidgets('sin citas muestra el CTA para añadir la primera', (tester) async {
    final controller = AppointmentsController(scheduler: _NoopScheduler());
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    expect(find.text('Citas'), findsOneWidget);
    expect(find.text('Añadir cita'), findsOneWidget);

    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('con una cita vencida por sacar muestra su título y el chip vencida',
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

    expect(find.text('Perfil lipídico'), findsOneWidget);
    expect(find.text('Vencida'), findsOneWidget);

    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
