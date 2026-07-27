# Sistema de temas

Prueba de concepto de temas seleccionables por el usuario. Un tema cambia
**colores y tipografía**; no cambia la navegación, los iconos, la maqueta ni el
significado de ningún color.

## Por qué cambiar de tema no cuelga la app

Un cambio de tema es **un repintado, no una recarga**. La secuencia completa es:

1. `ThemeProvider` cambia un enum y notifica.
2. `MyVitalsApp` —el **único** widget suscrito— reconstruye `MaterialApp`.
3. `MaterialApp` recibe otra `ThemeData` y el `InheritedWidget` de `Theme`
   invalida a quien la lea.
4. Los widgets se repintan con los tokens nuevos.

Ni se recrea el árbol, ni se vuelve a medir la maqueta, ni se toca la base de
datos, ni hay E/S en el camino. Las tres decisiones que lo sostienen:

- **`ThemeData` memoizada** (`AppThemeCatalog.themeOf`). `ColorScheme.fromSeed`
  deriva la rampa tonal con aritmética en espacio HCT; se hace una vez por tema
  y se guarda. Un test comprueba que dos llamadas devuelven la misma instancia.
- **Fuentes empaquetadas**, no descargadas. Antes se resolvía Inter por red con
  `google_fonts`: la primera vez había que bajarla, así que cambiar de tema
  podía provocar un parpadeo de fuente —o fallar sin conexión—. Ahora los `.ttf`
  viajan en el binario (~2 MB) y el cambio es determinista y funciona offline.
- **Nadie escucha al provider.** Las pantallas leen `Theme.of(context)`, que es
  una búsqueda O(1). Si una pantalla hiciera `watch` sobre `ThemeProvider`, se
  reconstruiría entera sin necesidad.

La preferencia se lee **antes de `runApp`**, para que el primer frame ya salga
vestido y no haya un destello del tema por defecto en cada arranque.

## Los colores siguen significando lo mismo

Tres vocabularios, y ninguno depende del tema:

- **`ClinicalStatus`** — `info` · `optimal` · `caution` · `alert` · `neutral`.
  Qué tan bien está un valor.
- **`MetricFamily`** — `vitals` · `anthropometry` · `lipids` ·
  `bodyComposition`. De qué indicador hablamos.
- **`ContentCategory`** — `heart` · `nutrition` · `emotional` · `sports` ·
  `sleep` · `daily`. De qué habla un contenido de «Descubre». Un artículo de
  nutrición no está «óptimo»: por eso no reutiliza la paleta clínica.

El reparto de responsabilidades es el punto entero:

| Quién | Decide |
|---|---|
| `core/utils/health_classifiers.dart` | Si 128/84 es «elevada». Criterio clínico, viene de los rangos del backoffice. |
| El tema | Con qué ámbar exacto se pinta «elevada». |

Un tema **no puede** decidir que «óptimo» sea morado, ni apagar el ámbar a gris,
ni dejar una insignia por debajo del contraste AA.
`test/core/theme/semantic_contract_test.dart` lo verifica sobre todos los temas
del catálogo —franja de matiz, saturación mínima, separación entre familias y
contraste en los tres fondos posibles— y el build falla si un tema lo incumple.
Añadir un tema lo somete automáticamente a todas las reglas.

## Anatomía

```
core/theme/
├── theme_catalog.dart        Registro de temas + ThemeData memoizada
├── theme_context.dart        Theme.of(context).surfaces / .clinical / .metrics / .type
├── semantic_contract.dart    Las reglas, como aritmética comprobable
├── app_theme.dart            Fachada obsoleta (pantallas sin migrar)
├── tokens/
│   ├── tone.dart             accent + surface + onAccent, y BadgeIdiom
│   ├── clinical_palette.dart ClinicalStatus → Tone
│   ├── metric_palette.dart   MetricFamily → Tone
│   ├── content_palette.dart  ContentCategory → Tone (+ nivel y estado)
│   ├── app_surfaces.dart     Lienzo, tarjeta, tinta, radios, idiomas
│   └── app_typography.dart   Roles: numeral, sectionLabel, meta…
└── themes/
    ├── pulso_clinico.dart    Azul clínico, denso, insignias sólidas
    ├── consulta_serena.dart  Lienzo cálido, serif, insignias suaves
    └── type_scale.dart       Escala y pesos de fuente variable
```

## Cómo se usa

```dart
final theme = Theme.of(context);      // una vez por build, no veinte

theme.surfaces.card                   // superficies y forma
theme.type.numeral                    // roles tipográficos
theme.clinical.tone(cat.status)       // estado clínico → color
theme.metrics.tone(MetricFamily.vitals)  // identidad del indicador
theme.content.tone(ContentCategory.sleep)  // identidad del contenido
```

Reglas:

- **Nunca** escribas un `Color(0xFF…)` en una pantalla. Si no hay token para lo
  que necesitas, el token es lo que falta.
- **Nunca** preguntes qué tema está activo. Si el comportamiento debe cambiar
  entre temas, eso es un token (así nacieron `badgeIdiom` y `monitorBezel`).
- Para un estado clínico usa `StatusChip`, que ya resuelve el idioma del tema.
- El color nunca va solo: acompáñalo de forma, icono o texto.

## Añadir un tema

1. Crea `themes/mi_tema.dart` con las cinco extensiones.
2. Añade el valor a `AppThemeId` y su ficha a `AppThemeCatalog.specs`.
3. `flutter test`. El contrato semántico dirá qué falta.

No hace falta tocar ninguna pantalla, ni la ficha del selector: el muestrario se
dibuja **dentro** del tema que describe y sus colores se leen de los propios
tokens, así que no puede desincronizarse.

## Estado de la migración

Migrado: **todo el flujo de arranque** —splash, bienvenida, identificación,
verificación, asistente de alta (3 pasos) y panel—, **el camino de registrar un
indicador completo** —la hoja «Registrar indicadores» y las cuatro pantallas:
antropometría, signos vitales, perfil lipídico y composición corporal—, **el
historial completo** —el índice y las cuatro vistas de categoría con sus
gráficas—, **Descubre completo** —el muro, sus seis tipos de tarjeta y la hoja de
detalle— y **Perfil y ajustes al completo** —las 18 pantallas—, la barra de
navegación y los widgets compartidos que usan
(`ActionButton`, `StatusChip`, `BmiStatusBadge`, `MainAppBar`,
`SecondaryAppBar`, `DashedBorderContainer`, `DismissibleInfoBanner`,
`ProfileSettingsLayout`…).

En las pantallas de registro, tres sustituciones cargan con casi todo el
trabajo, y las tres consisten en pedir el SIGNIFICADO en vez del color:

| Antes | Ahora |
|---|---|
| `MetricColors.vitalsColor` | `theme.metrics.tone(MetricFamily.vitals)` |
| `bpCat.color` + `Container` propio | `StatusChip(status: bpCat.status, …)` |
| Degradado de 4 hexadecimales | `theme.clinical.severityRamp` |

La rampa importa más de lo que parece: era el mismo azul→verde→ámbar→rojo
escrito a mano en dos archivos, y con el token el ORDEN CLÍNICO lo fija la
paleta, así que no puede quedar al revés en una pantalla y bien en otra.

La distinción que estas pantallas hacen visible: **hay dos vocabularios y no se
mezclan**. En composición corporal, el % de grasa se pinta con el tono CLÍNICO
—verde si la clasificación dice «normal»— mientras la masa muscular se pinta con
el color de la FAMILIA, porque no hay clasificación que aplicarle. Se ven una al
lado de la otra en la misma pantalla, y el color dice cuál es cuál.

Cuando un ayudante necesita un color, recibe un [Tone] ya resuelto y no un
`Color`. Así el filete, la cifra y el pulgar de un control salen del mismo sitio
por construcción, y no por acordarse de pasar el mismo valor tres veces.

### Descubre: por qué hizo falta un token nuevo

«Descubre» tenía su propia paleta en
`features/discover/presentation/theme/discover_palette.dart`: seis acentos
editoriales escritos a mano —rojo corazón, verde nutrición, violeta emocional,
naranja deporte, índigo sueño, turquesa día a día— más los del nivel de una
rutina y el estado de un reto. Ningún tema podía tocarlos, así que era la única
sección de la app que se veía igual pasara lo que pasara.

Reutilizar la paleta clínica habría sido mentir: un artículo de nutrición no está
«óptimo». Así que la sección pedía un vocabulario propio, y eso es
[ContentPalette]. `DiscoverPalette` se queda con lo único que de verdad era suyo
—el ICONO de cada categoría, que no cambia entre temas— y el color lo pone ahora
el tema.

El contrato semántico lo cubre igual que a las familias: franja de matiz por
categoría, las seis mutuamente distinguibles, y 4,5:1 sobre la tarjeta, sobre su
propio tinte y en relleno sólido. **Al escribirlo cazó cinco defectos** en los
valores que yo había propuesto: tres tintes por debajo de AA, un violeta que en
realidad era índigo, y dos categorías a 19,6° de matiz —que el usuario habría
confundido de un vistazo—. De paso quedó claro que el 12 % de mezcla que usaba
`Tone.from` para derivar tintes deja el acento en 4,3–4,5:1 sobre su propio
tinte: al 8 % pasa con margen.

### Las gráficas

`core/ranges/chart_bands.dart` pinta las zonas de referencia del paciente.
Tenía su propia tabla de hexadecimales, documentada como «la MISMA paleta
semántica de los clasificadores» —copiada a mano, o sea: podía dejar de serlo sin
que nada avisara, y el fondo de la gráfica pintaba un ámbar mientras la insignia
de al lado pintaba otro—. Ahora traduce el código de banda del servidor a
[ClinicalStatus] y recibe la `ClinicalPalette` del tema.

Tres reglas para las series de datos, que las cuatro gráficas cumplen:

- **La serie va en el acento de SU familia.** Una serie no está «bien» ni «mal»,
  así que NO sale de la paleta clínica. (Antes la de IMC era un azul suelto con
  puntos verde oscuro: ni la familia —antropometría es ámbar— ni un estado.)
- **Los umbrales y las zonas sí son clínicos.** La franja saludable de IMC es
  `optimal`; el corte de colesterol ≥ 200 es `alert`. El corte lo fija el
  clasificador; el color, el tema.
- **Con dos series** —sistólica y diastólica— la primera lleva el acento de la
  familia y la segunda el tono frío (`info`), que el contrato garantiza separado
  en matiz de los cálidos. Cuando haya más gráficas de varias series, lo que
  falta es un token de «serie secundaria», no repetir esta decisión.

En las pantallas de bienvenida, identificación y verificación se aplicó **solo el
tema**: textos, botones, rutas y comportamiento son idénticos a los de `main`
(verificado comparando literales y rutas contra `origin/main`). El rediseño del
sistema para esas pantallas —lámina A2, con el párrafo de beneficios y el
descargo médico— está pendiente de decidir aparte.

**No queda nada sin migrar.** `core/constants/metric_colors.dart` ya no existe:
su último usuario era `health_goals_screen.dart`. `reminders_screen.dart` era el
último de `AppTheme`, la fachada obsoleta.

En Perfil apareció un caso que no encajaba en ningún vocabulario: las **once
filas de ajustes**, cada una con su cuadradito de color. Eso no es semántica —un
ajuste no está «óptimo» ni pertenece a una familia de indicador— sino
ORIENTACIÓN: el color es lo que te permite volver a encontrar «Idioma» sin leer
las once. Salen de la paleta de CONTENIDO, que es el único juego de acentos que
la app ya garantiza mutuamente distinguibles y legibles en cualquier tema. Cada
fila conserva la familia de matiz que tenía, así que se reconoce igual.

Y un hallazgo: los cuatro grupos del **glosario** llevaban su color escrito a
mano en `glossary_data.dart` —un archivo de DATOS—, y encima uno distinto del
resto de la app: los lípidos eran ámbar allí y teal en el panel. Ahora el dato
dice de qué `MetricFamily` habla y el color lo pone el tema, así que ya no
pueden discrepar.

Dos cosas que se quedan a propósito con color fijo:

- Los **PDF y CSV exportados**. Son documentos, no interfaz: el informe que le
  llevas al médico no debería cambiar de aspecto según el tema que tengas puesto.
- Los **botones «Exportar a PDF» y «Excel (CSV)»**, en el rojo y el verde de esos
  dos formatos. Mapearlos a `alert` y `optimal` sería mentir: exportar un archivo
  no es una alerta ni un resultado óptimo.

Deudas conocidas, anteriores a este trabajo:

- `identify_screen.dart` y `verify_screen.dart` tienen **todos sus textos en
  español escritos a mano**, sin pasar por `l10n`. Como el resto de la app sigue
  el idioma del dispositivo, en un móvil en inglés esas dos pantallas se ven en
  español mientras las demás están en inglés.
- En `record_anthropometric_screen.dart`, el bloque de **perímetros corporales**
  tiene su rótulo y sus seis etiquetas en español a mano (`'Cintura'`,
  `'Cadera'`…), con el mismo efecto en un dispositivo en inglés. Lo mismo con el
  selector de laboratorio de `record_lipid_screen.dart` («¿En qué laboratorio te
  hiciste el examen?», «No indicado / no sé», «Otro (especificar)») y con
  «Músculo esquelético» en `record_body_composition_screen.dart`.
- El aviso de «guardado» de composición corporal usa el color de la FAMILIA,
  mientras las otras tres pantallas usan el verde de éxito. Se dejó como estaba
  —solo se cambió el color a mano por su token— porque unificarlo sería cambiar
  la interfaz, no aplicar el tema.
- En la hoja «Registrar indicadores», solo **Antropometría** navega; las otras
  tres tarjetas cierran la hoja sin ir a ninguna parte. Las cuatro rutas existen
  y las cuatro pantallas se abren desde el panel y desde Historial, así que es
  un cable sin conectar, no una pantalla que falte.

## El flujo de entrada

La **cuenta es obligatoria**: no hay modo local. El recorrido es

```
/                → selector de tema (temporal; su sitio es Perfil → Tema de la app)
/splash          → arranque; pasa quien tiene SESIÓN ACTIVA o ALTA PENDIENTE
/intro           → portada: logotipo, tres características, dos caminos
   ├─ Iniciar sesión → /identify → /verify        → /dashboard
   └─ Registrarse    → /onboarding (3 pasos)      → /dashboard
```

Reglas que sostienen esa promesa, y dónde viven:

- **Da paso una sesión activa O un alta pendiente** (`splash_screen.dart`).
- **El correo es obligatorio en el alta**, porque es el identificador con el que
  se crea la cuenta (`PersonalInfoScreen.requireEmail`). Desde Perfil sigue
  siendo opcional: ahí solo se edita.
- **Cerrar sesión devuelve a la portada** y NO borra los registros locales:
  siguen en la base del dispositivo y vuelven a subir al reentrar.

`test/core/router/auth_required_test.dart` fija el invariante: falla si alguien
vuelve a enrutar la portada antigua, si una pantalla navega al asistente
esquivando el registro, o si reaparece la bandera que lo permitía.

## Sin conexión: el alta se difiere, no se pierde

La cuenta es obligatoria, pero exigir que el servidor esté disponible **en ese
instante** convertiría un corte de red en un muro: el usuario rellena sus datos,
se queda fuera y los pierde. Así que el alta distingue tres desenlaces, y la
diferencia la da `AuthNetworkException`:

| Qué pasó | Qué hace la app |
|---|---|
| El servidor acepta | Cuenta creada, sesión guardada, al panel |
| Falla la RED o el servidor está caído (5xx) | Datos en el dispositivo, alta marcada pendiente, **el usuario entra** |
| El servidor RECHAZA el dato (4xx) | Muestra el motivo y se queda en el paso: reintentar no arregla un correo duplicado |

Sin esa distinción, un corte de red y un correo duplicado serían el mismo error y
habría que tratarlos igual — mal en los dos casos.

El alta pendiente vive en `core/auth/pending_account.dart`:

- `PendingAccountStore` — la bandera y el último motivo, persistidos. **No guarda
  copia del perfil**: los datos ya están en `UserProfileProvider`, así que si el
  usuario corrige un correo mal escrito, el reintento usa el corregido.
- `AccountDraft` — los campos que necesita `register`, ya resueltos. La función
  recibe esto y no el provider, porque el provider carga la foto por canales de
  plataforma y dependerlo haría la lógica imposible de probar.
- `flushPendingAccount(draft)` — el intento. Devuelve el desenlace.

**Cuándo se reintenta:** en cada arranque de la app (`splash_screen`, sin
bloquear la entrada) y cuando el usuario pulsa el botón del aviso o
«Sincronizar ahora». Al crearse la sesión, `SyncService` despierta solo y sube
todo lo que se acumuló mientras no había cuenta.

Los **registros de salud** ya eran local-first y no cambian: los repositorios
escriben en SQLite sin mirar la sesión.

`test/core/auth/pending_account_test.dart` cubre los cuatro desenlaces con un
cliente HTTP simulado —incluyendo que un 5xx cuente como reintentable y un 4xx
no— más que el estado sobreviva al reinicio.

La migración es incremental a propósito: había ~1.160 colores a mano repartidos
por la app, y hacerlo de golpe garantizaba dejar media interfaz a medias. Al
migrar una pantalla, sustituye `AppTheme.primaryColor` por el token que toque y
borra el import; cuando no queden usos, `app_theme.dart` desaparece.
