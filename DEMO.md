# Modo demostración

Arranca la app con **dos años de historia clínica ya dentro** —perfil, ajustes,
objetivos, recordatorios y unos 630 registros— para tomar capturas o grabar
vídeo sin registrar nada a mano.

```sh
flutter run -d chrome --dart-define=DEMO_MODE=true
```

Y ya está: se salta la portada, el registro y el selector de tema, y abre
directamente en el panel con todo puesto.

## Qué NO toca

Es la parte importante, porque una demo que ensucia la instalación de al lado
no sirve para nada:

| | Dónde va en la demo | Qué queda al cerrar |
|---|---|---|
| Preferencias, perfil, ajustes | Un almacén **en memoria** | Nada |
| Mediciones | `my-vitals-demo.db`, archivo aparte | Se borra y se resiembra en el siguiente arranque |
| Red | No se emite ninguna petición | — |

La base de datos de producción (`my-vitals-db.db`) no se abre siquiera. Se puede
arrancar la demo, tocar todos los ajustes que se quiera y cerrarla: al volver a
abrirla está otra vez en el estado inicial, y una instalación real en el mismo
dispositivo sigue intacta.

Sin `--dart-define=DEMO_MODE=true`, `kDemoMode` es una constante `false` y el
compilador **elimina del binario** todo `lib/core/demo/` y las ramas que lo
llaman. Una build de producción no puede entrar en este modo ni por accidente.

## Opciones

Todas se pasan como `--dart-define`, y sirven para repetir la misma captura en
otro idioma o con el otro acabado sin tocar una línea:

| Bandera | Valores | Por defecto |
|---|---|---|
| `DEMO_MODE` | `true` | *(apagado)* |
| `DEMO_LANG` | `es` · `en` · `de` · `pt` · `it` | `es` |
| `DEMO_THEME` | `pulsoClinico` · `consultaSerena` | `pulsoClinico` |
| `DEMO_UNITS` | `metric` · `imperial` | `metric` |

```sh
# La misma pantalla, en inglés y con el otro tema
flutter run -d chrome \
  --dart-define=DEMO_MODE=true \
  --dart-define=DEMO_LANG=en \
  --dart-define=DEMO_THEME=consultaSerena
```

## Qué historia cuenta

Daniel Ospina, 42 años, 176 cm. Dos años cuidándose, y los datos lo enseñan:

| | Hace dos años | Hoy |
|---|---|---|
| Peso · IMC | 92,4 kg · 29,8 *(sobrepeso)* | 76,8 kg · 24,8 *(normal)* |
| Tensión | 138/88 *(elevada)* | 118/76 *(normal)* |
| Pulso en reposo | 78 lpm | 62 lpm |
| Colesterol total · LDL · HDL | 236 · 158 · 38 | 178 · 102 · 54 |
| Grasa corporal · visceral | 31,4 % · nivel 13 | 20,6 % · nivel 7 |

Las cadencias son las de un usuario real, no las de un generador: la tensión se
mide en casa cada dos días (~420 lecturas), el peso y la bioimpedancia una vez
por semana (105 cada uno), la cinta métrica una vez al mes y la analítica cada
trimestre (9 paneles). Hay mesetas, algún síntoma suelto y un repunte cada
diciembre, porque una línea perfecta no se parece a nadie.

Los objetivos de salud están puestos **a medias a propósito**: el de peso sigue
en curso (faltan ~1,8 kg) y el de grasa corporal ya está cumplido, para que una
sola captura del panel enseñe los dos estados de la interfaz de metas.

La generación es **determinista**: la misma fecha produce exactamente los mismos
números, así que una captura repetida semanas después sale idéntica.

## Cómo está montado

```
lib/core/demo/
  demo_mode.dart      Las banderas. Constantes de compilación, nada más.
  demo_dataset.dart   Genera los registros. Puro: ni disco, ni red, ni reloj.
  demo_seeder.dart    Lo escribe: preferencias en memoria + base de datos aparte.
```

`demo_dataset.dart` no toca nada de fuera, y por eso se puede comprobar entero
desde una prueba unitaria. `test/core/demo/` vigila lo que un generador de datos
falsos rompe con facilidad —que los valores sean posibles, que las familias no
se contradigan (el IMC sale del peso y la talla, el VLDL de los triglicéridos,
los kg de músculo del peso de ese día) y que el resultado no cambie entre
ejecuciones— más que la siembra siga encajando con lo que leen los providers.

```sh
flutter test test/core/demo/
```

## Límites conocidos

Dos cosas que la siembra **no** puede arreglar, porque no dependen de los datos:

- **Las gráficas dibujan como mucho 6 puntos** (`recentRecords` en los cuatro
  `*_history_tab.dart`), sean cuales sean el filtro y el volumen de datos. En la
  analítica, que es trimestral, esos 6 puntos cubren 15 meses y la gráfica se lee
  perfecta; en tensión o peso cubren dos semanas, así que el filtro «Siempre»
  enseña una línea plana reciente en vez de la mejora de dos años.
- **La tarjeta de «Progreso de Autocuidado» está escrita a mano** en
  `profile_screen.dart`: nivel 1, barra al 15 % y medallas bloqueadas fijas. No
  se calcula desde los registros, así que un usuario con dos años de historia
  sigue saliendo como principiante.

Las dos son anteriores a la demo y afectan también a la app real. Para las
capturas: la analítica luce bien tal cual, y la tarjeta de progreso conviene
dejarla fuera del encuadre mientras no se calcule de verdad.
