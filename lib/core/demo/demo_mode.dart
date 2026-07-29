/// Modo demostración: la app arranca con dos años de historia clínica ya
/// dentro, para tomar capturas o grabar vídeo sin registrar cientos de
/// mediciones a mano.
///
/// Se enciende SOLO en tiempo de compilación:
///
/// ```sh
/// flutter run -d chrome --dart-define=DEMO_MODE=true
/// ```
///
/// Sin la bandera, [kDemoMode] es la constante `false` y el compilador elimina
/// del binario todo el paquete `core/demo` junto con las ramas que lo llaman:
/// una build de producción no puede entrar en este modo ni por accidente, y no
/// paga ni un byte por que exista.
///
/// **Nada de lo que siembra este modo se persiste.** Las preferencias viven en
/// memoria (ver `DemoSeeder`) y los registros van a una base de datos aparte
/// que se borra y se vuelve a sembrar en cada arranque. Cerrar la app deja la
/// demo exactamente como estaba; la instalación real del usuario no se toca.
library;

/// ¿Está la app corriendo como demostración?
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// Idioma con el que arranca la demo. Uno de los que soporta la app:
/// `es`, `en`, `de`, `pt`, `it`.
///
/// ```sh
/// --dart-define=DEMO_LANG=en
/// ```
const String kDemoLanguage = String.fromEnvironment(
  'DEMO_LANG',
  defaultValue: 'es',
);

/// Tema con el que arranca la demo: `pulsoClinico` o `consultaSerena`. Permite
/// sacar la misma captura con los dos acabados sin tocar la app.
///
/// ```sh
/// --dart-define=DEMO_THEME=consultaSerena
/// ```
const String kDemoTheme = String.fromEnvironment(
  'DEMO_THEME',
  defaultValue: 'pulsoClinico',
);

/// Sistema de unidades de la demo: `metric` o `imperial`.
const String kDemoUnits = String.fromEnvironment(
  'DEMO_UNITS',
  defaultValue: 'metric',
);
