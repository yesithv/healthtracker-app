/// Banderas de COMPILACIÓN del modo demostración.
///
/// Ojo con el reparto de papeles: la demo se enciende y se apaga **en tiempo de
/// ejecución** (ver `DemoSession`), porque cualquiera puede entrar desde la
/// portada y salir desde dentro. Lo que hay aquí sólo decide con qué estado
/// ARRANCA la app, y existe para las capturas guionizadas: poder lanzar la app
/// ya dentro de la demo, en un idioma y un tema concretos, sin tocar la
/// pantalla.
///
/// ```sh
/// flutter run -d chrome --dart-define=DEMO_MODE=true
/// ```
library;

/// Arranca ya dentro de la demo, sin pasar por la portada.
///
/// No es lo mismo que «la demo existe»: la demo existe siempre y se entra desde
/// la portada. Esto sólo se salta ese paso.
const bool kDemoAutoStart = bool.fromEnvironment('DEMO_MODE');

/// Idioma con el que arranca la demo automática (`es`, `en`, `de`, `pt`, `it`).
///
/// Vacío —lo normal— significa **no imponer ninguno**: la demo se ve en el
/// idioma del usuario, que es lo que ya resuelve `LocaleUnitsProvider` a partir
/// del dispositivo o de su elección. Sólo se rellena para forzar el idioma de
/// una captura concreta.
const String kDemoLanguage = String.fromEnvironment('DEMO_LANG');

/// Tema con el que arranca la demo automática: `pulsoClinico` o
/// `consultaSerena`. Vacío = se respeta el que tenga elegido el usuario.
const String kDemoTheme = String.fromEnvironment('DEMO_THEME');

/// Unidades de la demo automática: `metric` o `imperial`. Vacío = las del
/// usuario.
const String kDemoUnits = String.fromEnvironment('DEMO_UNITS');

/// ¿La demo automática impone además idioma, tema o unidades?
///
/// Al entrar desde la portada NUNCA se imponen: la demo tiene que verse en el
/// idioma y con el tema que el usuario ya tenía, o dejaría de parecerse a la
/// app que se le está enseñando.
bool get kDemoOverridesAppearance =>
    kDemoLanguage.isNotEmpty || kDemoTheme.isNotEmpty || kDemoUnits.isNotEmpty;
