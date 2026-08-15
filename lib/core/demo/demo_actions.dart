import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';

/// Entrar y salir de la demostración desde la interfaz.
///
/// `DemoSession` mueve el almacenamiento —preferencias y base de datos—, pero
/// eso no basta: los providers ya tienen en memoria lo que leyeron al arrancar,
/// y sin releerlos la pantalla seguiría enseñando el estado anterior. Aquí vive
/// ese segundo paso, junto con la navegación, porque necesita un `BuildContext`
/// y `DemoSession` no debe depender del árbol de widgets.

/// Entra en la demostración y aterriza en el panel.
///
/// Los comentarios de los registros se escriben en el idioma que el usuario
/// tiene puesto: la interfaz ya se traduce sola, pero el contenido no, y una
/// demo en inglés con notas en español se delata.
Future<void> enterDemo(BuildContext context) async {
  final reload = _providerReload(context);
  final router = GoRouter.of(context);
  final language = context.read<LocaleUnitsProvider>().locale.languageCode;

  await DemoSession.instance.enter(languageCode: language);
  await reload();

  router.go('/dashboard');
}

/// Sale de la demostración y devuelve al visitante a la portada, que es donde
/// puede registrarse o iniciar sesión de verdad.
Future<void> exitDemo(BuildContext context) async {
  final reload = _providerReload(context);
  final router = GoRouter.of(context);

  await DemoSession.instance.exit();
  await reload();

  router.go('/welcome');
}

/// Cierra sobre los providers ANTES del primer `await`.
///
/// Leerlos después de un `await` con el mismo `BuildContext` es justo el error
/// que persigue `use_build_context_synchronously`: entre medias el widget puede
/// haberse desmontado. Se capturan de una vez —y con ellos el router— y luego ya
/// no hace falta contexto.
Future<void> Function() _providerReload(BuildContext context) {
  final profile = context.read<UserProfileProvider>();
  final goals = context.read<HealthGoalsProvider>();
  final reminders = context.read<RemindersProvider>();
  final localeUnits = context.read<LocaleUnitsProvider>();
  final device = context.read<MeasuringDeviceProvider>();

  return () async {
    // La sesión va PRIMERO. Es un singleton, pero se relee igual: al entrar
    // aparece la identidad del personaje y al salir tiene que desaparecer, o la
    // app creería que sigue habiendo alguien dentro.
    //
    // Y va primero porque el resto la consulta: la báscula decide si puede
    // hablar con la API preguntando si hay paciente, así que releerla después
    // dejaba una ventana en la que salía a la red con la identidad de la demo,
    // que en el servidor no existe.
    await PatientSession.instance.load();
    await profile.reload();
    await goals.reload();
    await reminders.reload();
    await localeUnits.reload();
    await device.load();
  };
}
