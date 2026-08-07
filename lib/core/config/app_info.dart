/// Identidad de la aplicación para documentos generados (p. ej. la cabecera y el
/// pie del PDF consolidado de historia clínica, donde la app figura como la
/// FUENTE/autor de los datos autoreportados).
///
/// La versión se mantiene a mano en sincronía con `pubspec.yaml` (`version:`).
/// Se prefiere una constante a añadir `package_info_plus` solo para leer un
/// número: el árbol de dependencias no crece por un dato que ya conocemos en
/// tiempo de compilación. Si en el futuro se necesita la versión en más sitios,
/// migrar a `package_info_plus` es el paso natural.
class AppInfo {
  const AppInfo._();

  /// Nombre comercial de la app. NO es texto traducible: es la marca.
  static const String appName = 'MY VITALS';

  /// Versión visible, alineada con `pubspec.yaml`.
  static const String version = '0.1.0';
}
