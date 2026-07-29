# My Vitals — HealthTracker App

Aplicación móvil (Flutter) para que un paciente registre y siga sus propios
indicadores de salud: signos vitales, antropometría, perfil lipídico y
composición corporal. Funciona **local-first** —todo se guarda en SQLite en el
dispositivo y la app es plenamente usable sin red— y se sincroniza en ambos
sentidos con la **HealthTracker-Api**, que es además la fuente de verdad de los
rangos clínicos con los que se interpretan los valores.

---

## 1. Estado actual del proyecto

**Versión:** `0.1.0+1` · **Fase 0** (integración con la API con andamios de
autenticación) · 22 commits, el último del 2026-07-29.

La app está **funcionalmente completa de punta a punta**: alta de paciente,
captura de las cuatro familias de indicadores, historiales con gráficas,
clasificación clínica, sincronización bidireccional, contenidos, ajustes, copia
de seguridad y cinco idiomas. Lo que queda pendiente es sustituir los andamios
de la Fase 0 por sus piezas definitivas.

### Qué está terminado

| Área | Estado |
|---|---|
| Persistencia local (SQLite, 4 tablas, migraciones v1→v3) | ✅ Estable |
| Captura y edición de los 4 tipos de registro | ✅ Estable |
| Historiales con gráficas y exportación PDF/CSV | ✅ Estable |
| Clasificación clínica con rangos del servidor + respaldo offline | ✅ Estable |
| Sincronización de subida (app → API) y de bajada (API → app) | ✅ Funcionando |
| Alta de cuenta, incluida el **alta diferida** sin red | ✅ Funcionando |
| Sistema de temas con contrato semántico verificado | ✅ Estable |
| Internacionalización (es · en · pt · it · de) | ✅ ~528 claves por idioma |
| Copia de seguridad / restauración en JSON | ✅ Formato v1.0 |
| Pruebas + CI (analyze, test, build web, despliegue a Pages) | ✅ 16 archivos de prueba |

### Andamios y deuda conocida

Están marcados en el código como «Fase 0» y con su hueco de reemplazo escrito:

- **Verificación de identidad**: la pantalla `/verify` acepta una contraseña de
  desarrollo (`1234`). En Fase 1 entra ahí el OTP de Firebase (SMS/email): mismo
  paso del flujo y misma UI, distinto mecanismo
  (`features/auth/presentation/screens/verify_screen.dart`).
- **Identidad hacia la API**: se envía la cabecera `X-Patient-Public-Id` porque
  todavía no hay IdP/JWT. En Fase 1 el paciente sale del token y
  `ApiConfig.patientPublicId` desaparece.
- **Pantalla de arranque**: la ruta `/` es hoy el **selector de tema**, no el
  splash, para poder recorrer el flujo entero con cualquiera de los dos temas.
  Al reubicar el selector dentro de Perfil basta devolver `/` a `SplashScreen`
  (`core/router/app_router.dart`).
- **Feed de «Descubre»**: se sirve desde las semillas empaquetadas en
  `assets/data/`. El cliente contra `GET /api/v1/discover/feed` ya existe;
  conectarlo es cambiar un único método (`DiscoverRepository._readFreshSource`).
- **Bajada parcial**: la importación desde el servidor materializa antropometría
  y composición corporal; signos vitales y lípidos hoy solo suben.
- **`core/theme/app_theme.dart`** es una fachada obsoleta que sigue viva para las
  pantallas aún sin migrar al sistema de tokens.
- El workflow de despliegue publica desde la rama `dev`, que ya no existe en el
  remoto (se fusionó a `main`): habrá que reapuntarlo o recrearla.

---

## 2. Especificaciones técnicas

### Plataforma y lenguaje

| Elemento | Valor |
|---|---|
| Framework | Flutter (canal estable, `3.44.8` en CI) |
| SDK Dart | `^3.11.3` |
| Lenguaje | Dart con null-safety |
| Objetivos compilables | Android · iOS · Web · Linux · macOS · Windows |
| Objetivos ejercitados | **Android** y **Web** (el resto son los *runners* generados por Flutter, sin trabajo específico) |
| Lints | `flutter_lints ^6.0.0` |
| Volumen | ~26.800 líneas de Dart en `lib/` (sin contar `l10n/generated`) |

### Arquitectura

Organización **feature-first** sobre un núcleo compartido:

```
lib/
├── main.dart              Arranque por pasos + árbol de providers
├── core/                  Lo transversal
│   ├── auth/              Sesión del paciente, cliente de auth, alta diferida
│   ├── config/            ApiConfig (inyectado con --dart-define)
│   ├── database/          DatabaseService (esquema) + repositorios por entidad
│   ├── sync/              Subida, bajada, mapeadores y clientes HTTP
│   ├── ranges/            Rangos de referencia del servidor y de laboratorio
│   ├── providers/         Estado de aplicación (ChangeNotifier)
│   ├── theme/             Tokens, catálogo de temas y contrato semántico
│   ├── router/            Rutas GoRouter
│   ├── validation/        Formateadores y validadores de entrada
│   ├── services/          Notificaciones, biometría, copia de seguridad, imagen
│   ├── utils/             Clasificadores clínicos
│   └── widgets/           Componentes compartidos
├── features/              dashboard · history · discover · profile · auth ·
│                          onboarding · account · theming · welcome · splash
└── l10n/                  .arb por idioma + delegados generados
```

Cada *feature* sigue `data/` (modelos, repositorios) + `presentation/`
(pantallas, widgets), y los cuatro tipos de registro comparten la misma anatomía:
modelo → repositorio singleton → pantalla de captura → pestaña de historial →
tarjeta de dashboard.

**Gestión de estado:** `provider` (`ChangeNotifier`). Los repositorios de
registros y la sesión son *singletons* expuestos con `.value`, para que el código
de red no dependa del árbol de widgets. `SyncService` y `DiscoverProvider` se
crean con `lazy: false` porque escuchan eventos desde el arranque.

**Navegación:** `go_router` con rutas declarativas y un `ShellRoute` que envuelve
las cuatro pestañas principales (`/dashboard`, `/history`, `/discover`,
`/profile`) en `AppShell`; captura, ajustes, ayuda y auth son rutas de pila.

**Arranque** (`main.dart`), por pasos y con cada uno aislado en su propio
`try/catch` para que un fallo no tumbe la app: base de datos → notificaciones →
sesión y alta pendiente → rangos de referencia → precalentado del feed → lectura
del tema **antes de `runApp`**. Todo envuelto en `runZonedGuarded`.

### Persistencia

- **SQLite** vía `sqflite` (móvil/escritorio) y `sqflite_common_ffi_web` +
  `sqlite3.wasm` (web), detrás de una única `DatabaseService`.
- Base `my-vitals-db.db`, **esquema v3** con migraciones incrementales y
  aditivas: v2 añadió `lab_code`; v3 añadió los seis perímetros corporales y
  `muscle_pct`, y normalizó a centímetros las tallas importadas en metros.
- Cuatro tablas: `anthropometric_records`, `vital_sign_records`,
  `lipid_records`, `body_composition_records`. Todas con `id` (UUID),
  `measurement_date`, `created_at`, `updated_at` e `is_synced`.
- **Preferencias** en `SharedPreferences`: perfil, idioma, unidades, metas,
  recordatorios, tema, sesión y cachés de rangos y de «Descubre».

### Integración con la API

`ApiConfig` se inyecta en compilación con `--dart-define`; no se versionan
entornos. Identidad temporal por cabecera `X-Patient-Public-Id`.

| Endpoint | Uso |
|---|---|
| `POST /api/v1/auth/register` · `login` · `lookup` · `activate` | Alta, entrada y comprobación de identidad |
| `POST /api/v1/me/measurements` | Subida de registros pendientes (upsert idempotente) |
| `GET  /api/v1/me/measurements` | Bajada del historial del paciente |
| `GET  /api/v1/me/reference-ranges` | Bandas clínicas ya resueltas por dispositivo/sexo/edad |
| `GET  /api/v1/me/device` · `/api/v1/measuring-devices` | Dispositivo del paciente y catálogo |
| `GET  /api/v1/labs` · `/api/v1/labs/{code}/ranges` | Catálogo de laboratorios y sus rangos |
| `GET  /api/v1/discover/feed?lang=` | Contenidos (cliente listo, aún sin conectar) |

**Política de sincronización.** La subida reúne lo no sincronizado de las cuatro
familias, lo aplana con `MeasurementMapper` y **solo marca como sincronizado si
el servidor responde bien**: ante cualquier fallo no marca nada, así el siguiente
intento reintenta lo pendiente. Se dispara con *debounce* de 2 s tras guardar, al
iniciar sesión y al arrancar con sesión activa. La bajada deduplica por instante
de medición, de modo que repetirla nunca duplica registros.

**Degradación sin red**, como regla del proyecto y no como excepción: sin
catálogo de laboratorios se cae a «Otro» con texto libre; sin rangos del servidor
los clasificadores usan sus cortes de fábrica; sin servidor durante el registro,
el alta queda **pendiente** y el usuario entra igual (se reintenta en cada
arranque).

### Sistema de temas

Dos temas seleccionables —**Pulso Clínico** (azul clínico, denso, insignias
sólidas) y **Consulta Serena** (lienzo cálido, serif, insignias suaves)— sobre un
vocabulario de tokens. Detalle completo en
[`lib/core/theme/README.md`](lib/core/theme/README.md). Lo esencial:

- Cambiar de tema es **un repintado, no una recarga**: `ThemeData` memoizada, un
  único widget suscrito (`MyVitalsApp`) y cero E/S en el camino. La preferencia
  se lee antes de `runApp` para que no haya destello del tema por defecto.
- Tres vocabularios semánticos independientes del tema: `ClinicalStatus`
  (info · optimal · caution · alert · neutral), `MetricFamily` (vitals ·
  antropometría · lípidos · composición) y `ContentCategory` (corazón ·
  nutrición · emocional · deporte · sueño · diario).
- **Separación de responsabilidades**: `health_classifiers.dart` decide si 128/84
  es «elevada»; el tema decide con qué ámbar exacto se pinta. Un tema no puede
  cambiar el significado de un color ni bajar del contraste AA —
  `semantic_contract_test.dart` lo verifica sobre todo el catálogo y el build
  falla si se incumple.

### Tipografías y assets

Las fuentes van **empaquetadas**, no descargadas en ejecución: `google_fonts`
resolvía la familia por red la primera vez, así que cambiar de tema podía
provocar un parpadeo de fuente o fallar sin conexión. Se embarcan Newsreader e
Inter (variables, eje `wght`) e IBM Plex Sans/Mono (400/600).

Las banderas de los selectores de país e idioma son emoji y ninguna de esas
familias los trae, así que se empaqueta un **recorte de Noto Color Emoji** con
exactamente las 47 banderas del catálogo de países: 159 KB en lugar de 10,8 MB
(`tool/subset_flag_font.py`).

### Internacionalización

Cinco idiomas —**español, inglés, portugués, italiano y alemán**— con archivos
ARB y `flutter_localizations` (plantilla `app_en.arb`, ~528 claves por idioma,
generación configurada en `l10n.yaml`). Aparte del idioma, las unidades son
conmutables entre **métricas e imperiales**.

### Dependencias principales

| Paquete | Para qué |
|---|---|
| `go_router` | Navegación declarativa |
| `provider` | Estado de aplicación |
| `sqflite` / `sqflite_common_ffi_web` | Persistencia local (móvil / web) |
| `shared_preferences` | Preferencias y cachés |
| `http` | Clientes de la API |
| `fl_chart` | Gráficas de historial |
| `flutter_local_notifications` · `timezone` · `flutter_timezone` | Recordatorios programados |
| `local_auth` | Desbloqueo biométrico |
| `image_picker` | Foto de perfil |
| `file_picker` · `share_plus` · `path_provider` | Copia de seguridad y restauración |
| `pdf` · `printing` · `csv` · `screenshot` | Exportación desde los historiales |
| `url_launcher` · `uuid` · `intl` | Enlaces externos, identificadores y formatos |

### Pruebas y CI

16 archivos en `test/`, escritos como **invariantes con su motivo documentado**:
cada uno fija un defecto que ya ocurrió una vez.

- `theme/semantic_contract_test.dart` — franja de matiz, saturación mínima,
  separación entre familias y contraste AA en todos los temas del catálogo.
- `theme/no_theme_anchored_styles_test.dart` — prohíbe estilos calculados sobre
  un tema concreto.
- `theme/hint_style_test.dart` — un texto de ejemplo no puede parecer un dato ya
  escrito.
- `theme/icon_enclosure_shape_test.dart` — un icono encerrado va en cuadrado
  redondeado, nunca en círculo.
- `l10n/arb_glyph_coverage_test.dart` y `flag_glyph_coverage_test.dart` — toda
  cadena visible y toda bandera tienen que poder **dibujarse** con las fuentes
  empaquetadas (nada de «tofu»).
- `l10n/no_hardcoded_strings_test.dart` — sin texto fijo en la interfaz.
- `router/auth_required_test.dart` — la cuenta es obligatoria: ningún camino
  entra sin sesión.
- `auth/pending_account_test.dart` — comportamiento del alta diferida.
- `sync/measurement_mapper_test.dart` y `legacy_import_mapper_test.dart` — mapeo
  en ambos sentidos.
- `ranges/lab_ranges_store_test.dart`, `ranges/reference_ranges_store_test.dart`,
  `validation/input_rules_test.dart`, `health_classifiers_test.dart`,
  `providers/measuring_device_provider_test.dart`.

**CI** (`.github/workflows/deploy-dev.yml`): en cada empujón a `dev` y en cada
pull request corre formato (solo avisa), `flutter analyze` y `flutter test`;
después compila web con `--base-href` y CanvasKit embebido, y publica en GitHub
Pages **solo desde la rama**, nunca desde un pull request.

---

## 3. Funcionalidades

### Acceso y cuenta

- **La cuenta es obligatoria** (ya no existe el modo local «explorar sin
  cuenta»), con dos caminos desde la portada: *ya tengo cuenta* → identificación
  por documento o email → verificación; o *soy nuevo* → asistente de alta.
- **Alta diferida**: si el servidor no responde durante el registro, el usuario
  entra igual y la cuenta se crea en el primer arranque con red. Un aviso
  persistente indica que el alta sigue pendiente.
- **Sin fuga de PII**: antes de verificar no se muestra ni el nombre ni el
  historial de quien solo ha tecleado un identificador.
- **Asistente de alta** en 3 pasos: datos personales (obligatorios), unidades de
  medida (con valor por defecto) y foto de perfil (opcional).
- **Desbloqueo biométrico** opcional al abrir la app.
- Pantalla de **cuenta y sincronización**: estado, última sincronización,
  «Sincronizar ahora» y reintento del alta pendiente.
- Los pacientes migrados del sistema anterior (`source = LEGACY`) reciben su
  historial en la primera sincronización.

### Registro de indicadores

Cuatro familias, cada una con captura, edición y validación en dos niveles
(formateadores que impiden teclear valores imposibles y validadores al
confirmar):

1. **Signos vitales** — sistólica, diastólica, frecuencia cardíaca, estado de
   actividad (reposo, ejercicio, postoperatorio) y síntoma (normal, mareo,
   dolor, fatiga).
2. **Antropometría** — peso, talla, IMC calculado y seis perímetros corporales
   (cintura, cadera, abdomen bajo, brazo, pierna y pecho/busto).
3. **Perfil lipídico** — colesterol total, LDL, HDL, VLDL y triglicéridos, con
   **selector de laboratorio** para que cada examen se interprete con los rangos
   del laboratorio donde se tomó (ATP III como respaldo).
4. **Composición corporal** — grasa corporal (%), masa muscular (kg y %), grasa
   visceral, edad metabólica, metabolismo basal, agua corporal y masa ósea, con
   el dispositivo de medición asociado.

Todos admiten fecha de medición y comentario libre.

### Interpretación clínica

- **Semáforo clínico** por indicador (óptimo · precaución · alerta · info),
  resuelto contra las bandas administradas en el backoffice y servidas ya
  resueltas para el paciente por dispositivo, sexo y edad.
- **Respaldo de fábrica offline**: sin sesión o sin red se usan cortes estándar,
  nunca se deja un valor sin interpretar.
- Insignias de estado, insignia de IMC y bandas de referencia dibujadas sobre las
  gráficas.

### Dashboard

Resumen del estado actual: tarjeta de perfil, signos vitales con trazo ECG,
histórico antropométrico, perfil lipídico, composición corporal e indicadores de
progreso contra las metas, más el aviso de alta pendiente cuando corresponde.

### Historial

- Índice por familia y pantalla dedicada por categoría.
- **Gráficas de evolución** (`fl_chart`) con bandas de referencia y ejes
  ajustados a los datos.
- Lista cronológica con edición y borrado de cada registro.
- **Exportación a PDF y CSV** con compartido nativo, desde cada pestaña.

### Descubre

Contenidos de salud servidos local-first (memoria → caché persistida → semilla
empaquetada), en los cinco idiomas: artículos con destacado y detalle en hoja
inferior, categorías (corazón, nutrición, emocional, deporte, sueño, diario),
rutinas de ejercicio con nivel y duración, retos con participantes y duración, y
consejos diarios. La semilla actual trae 8 artículos, 5 rutinas, 4 retos y 15
consejos por idioma. La pestaña abre sin *spinner* porque el feed se precalienta
en el arranque.

### Perfil y ajustes

| Sección | Qué hace |
|---|---|
| Cuenta y sincronización | Estado de sesión, sincronizar ahora, alta pendiente |
| Información personal | Nombre, fecha de nacimiento, sexo, email, nivel de actividad, foto |
| Dispositivo de medición | Selector del catálogo de básculas/bioimpedancia (local-first) |
| Metas de salud | Peso, grasa corporal, masa muscular y grasa visceral objetivo |
| Tema | Selector entre Pulso Clínico y Consulta Serena |
| Idioma | es · en · pt · it · de |
| Unidades | Métrico / imperial |
| Recordatorios | Avisos diarios por hora, con notificaciones locales y zona horaria del dispositivo |
| Privacidad y seguridad | Biometría, gestión de datos, cierre de sesión |
| Copia de seguridad | Exportar/importar todo en JSON (formato v1.0; versiones desconocidas se rechazan) |
| Ayuda y soporte | FAQ, glosario de términos clínicos, legal y contacto |

---

## 4. Puesta en marcha

```bash
# Requisitos: Flutter estable (3.44.x) con SDK de Dart ^3.11.3
flutter --version

flutter pub get

# Ejecutar apuntando a la HealthTracker-Api
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8081 \
  --dart-define=PATIENT_PUBLIC_ID=UUID-DEL-PACIENTE
```

Notas:

- Puertos del entorno: **8081** = HealthTracker-Api · 8080 = ACL · 8082 =
  BackOffice-Api.
- En el emulador de Android, el `localhost` del anfitrión es `10.0.2.2`.
- Sin `PATIENT_PUBLIC_ID` la sincronización queda deshabilitada; el resto de la
  app funciona igual (local-first).
- En `/verify`, la contraseña de desarrollo de la Fase 0 es `1234`.

### Comandos habituales

```bash
flutter analyze                  # análisis estático
flutter test                     # suite completa (incluye el contrato de temas)
dart format lib test             # formato
flutter gen-l10n                 # regenerar los delegados desde los .arb

flutter build apk --release
flutter build web --release --no-web-resources-cdn
```

### Al tocar ciertas piezas

- **Añadir un país** a `core/constants/countries.dart` obliga a rehacer el
  recorte de la fuente de banderas (`tool/subset_flag_font.py`);
  `flag_glyph_coverage_test.dart` lo señala con nombre y apellidos.
- **Añadir un tema** lo somete automáticamente a todo el contrato semántico.
- **Cambiar el esquema** de la base exige subir `_dbVersion` y añadir un paso
  aditivo en `_upgradeDB`.
- **Ajustar umbrales clínicos** se hace en el backoffice, no en
  `health_classifiers.dart`: los cortes de ese archivo son solo el respaldo
  offline.
