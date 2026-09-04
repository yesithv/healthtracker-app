import 'package:flutter/foundation.dart';

/// Con qué se llega a la pantalla del código, que decide qué se canjea.
///
/// Son dos códigos distintos y conviene no confundirlos:
///
///  - el que llega **al correo** cuando alguien entra por la puerta de la app. Lo protege el
///    propio buzón, así que se canjea con el correo;
///  - el que **dicta un agente por teléfono** después de verificar la identidad de un paciente
///    de la clínica. Ese viaja fuera del sistema, así que se canjea con el documento: sin él,
///    probar seis dígitos al azar acertaría el de alguien.
@immutable
class AccessTarget {
  /// El correo al que se mandó el código, o `null` si el código vino de la clínica.
  final String? email;

  const AccessTarget.email(String this.email);

  const AccessTarget.clinicCode() : email = null;

  /// ¿El código lo dictó un agente? Entonces hay que pedir el documento.
  bool get isClinicCode => email == null;
}
