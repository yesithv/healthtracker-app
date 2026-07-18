/// Configuración de acceso a la HealthTracker-Api (la sincronización de datos).
///
/// Los valores se inyectan en build con `--dart-define` para no versionar entornos:
///   flutter run \
///     --dart-define=API_BASE_URL=http://localhost:8080 \
///     --dart-define=PATIENT_PUBLIC_ID=UUID-DEL-PACIENTE
///
/// Notas de desarrollo:
/// - En el emulador de Android, `localhost` del host es `10.0.2.2`.
/// - [patientPublicId] es un ANDAMIO temporal: hoy la API resuelve al paciente por la
///   cabecera `X-Patient-Public-Id` mientras no hay auth real (IdP/JWT). En Fase 1 el
///   paciente saldrá del token y esta constante desaparece.
class ApiConfig {
  const ApiConfig._();

  /// URL base de la HealthTracker-Api (sin barra final). Puerto 8081 (8080=ACL, 8082=BackOffice-Api).
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081');

  /// `public_id` del paciente (andamio de auth de Fase 0). Vacío = sync deshabilitada.
  static const String patientPublicId =
      String.fromEnvironment('PATIENT_PUBLIC_ID', defaultValue: '');

  /// ¿Hay configuración mínima para sincronizar? (URL + identidad del paciente).
  static bool get isSyncConfigured =>
      baseUrl.isNotEmpty && patientPublicId.isNotEmpty;
}
