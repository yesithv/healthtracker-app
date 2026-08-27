/// Configuración de acceso a la HealthTracker-Api (la sincronización de datos).
///
/// Los valores se inyectan en build con `--dart-define` para no versionar entornos:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8081
///
/// Notas de desarrollo:
/// - En el emulador de Android, `localhost` del host es `10.0.2.2`.
/// - Ya no hay `PATIENT_PUBLIC_ID`: era un andamio que dejaba declarar por cabecera de
///   qué paciente se trataba, es decir, leer la historia clínica de cualquiera cambiando
///   un UUID. Quien identifica al paciente ahora es el token de sesión que emite el
///   servidor al canjear el código que el staff dicta por teléfono (ver [PatientSession]).
class ApiConfig {
  const ApiConfig._();

  /// URL base de la HealthTracker-Api (sin barra final). Puerto 8081 (8080=ACL, 8082=BackOffice-Api).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  /// ¿Está configurado a dónde hablar? La otra mitad —tener sesión— la decide
  /// `PatientSession.instance.isAuthenticated`, que cambia en caliente.
  static bool get isConfigured => baseUrl.isNotEmpty;
}
