# Demostración

En la portada, bajo «Iniciar sesión» y «Crear cuenta», hay un enlace: **ver la
demostración**. Abre la app con dos años de historia clínica de un paciente
inventado —perfil, ajustes, objetivos, recordatorios y unos 630 registros— y
deja navegarla entera, registrar y editar. Un aviso permanente arriba recuerda
que son datos de prueba y ofrece la salida, que devuelve a la portada.

Se ve en el **idioma del usuario**, incluidos los comentarios de los registros,
y con el **tema que ya tuviera elegido**: la demo tiene que parecerse a la app
que enseña, no a otra.

## Las dos garantías

Entrar no puede destruir nada de quien abre la demo, y salir devuelve todo como
estaba. Todo lo demás se apoya en esto:

**1. Las preferencias se copian antes de sembrar.** Lo que hubiera —el tema que
eligió, su idioma, un alta a medias— se guarda en un blob y se restaura íntegro
al salir. La demo no «limpia» al terminar: rebobina. Un `clear()` a secas
dejaría al visitante sin sus ajustes.

**2. Los registros van a otra base de datos.** `my-vitals-demo.db` es un archivo
distinto del de producción. Entrar cambia de archivo, salir vuelve al de siempre
y vacía el desechable. El historial real no se abre siquiera mientras dura la
demo — y por eso el visitante puede registrar y editar sin riesgo.

Mientras dura, tampoco sale ninguna petición a la API: la demo tiene sesión
sembrada, pero ese paciente no existe en el servidor.

## Comprobado de punta a punta

Con un usuario que ya tenía tema `consultaSerena` e idioma `pt`:

| | Antes | En demo | Después de salir |
|---|---|---|---|
| Ruta | `/intro` | `/dashboard` | `/intro` |
| Tema · idioma | consultaSerena · pt | consultaSerena · pt | consultaSerena · pt |
| Perfil | vacío | Daniel Ospina | vacío |
| Panel | sin datos | 630 registros | sin datos |

Las preferencias antes y después son idénticas byte a byte. El aviso de una sola
vez no vuelve a salir al recargar la página, y la demo sobrevive a un F5 sin
echar al visitante.

## Capturas guionizadas

Para generar capturas sin tocar la pantalla, la app puede arrancar ya dentro de
la demo. Es lo único que sigue siendo bandera de compilación:

```sh
flutter run -d chrome --dart-define=DEMO_MODE=true
```

| Bandera | Valores | Por defecto |
|---|---|---|
| `DEMO_MODE` | `true` | *(arranque normal)* |
| `DEMO_LANG` | `es` · `en` · `de` · `pt` · `it` | el idioma del usuario |
| `DEMO_THEME` | `pulsoClinico` · `consultaSerena` | el tema del usuario |
| `DEMO_UNITS` | `metric` · `imperial` | las del usuario |

Idioma, tema y unidades sólo se imponen si se piden a mano; al entrar desde la
portada nunca se tocan.

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

Los objetivos están puestos **a medias a propósito**: el de peso sigue en curso
(faltan ~1,8 kg) y el de grasa corporal ya está cumplido, para que una sola
pantalla enseñe los dos estados de la interfaz de metas.

La generación es **determinista**: la misma fecha produce los mismos números, así
que una captura repetida semanas después sale idéntica.

## Cómo está montado

```
lib/core/demo/
  demo_mode.dart      Banderas de compilación. Sólo el arranque guionizado.
  demo_session.dart   El interruptor: entrar, salir, copia y vuelta atrás.
  demo_dataset.dart   Genera los registros. Puro: ni disco, ni red, ni reloj.
  demo_seeder.dart    Qué perfil y qué ajustes tiene el personaje.
  demo_actions.dart   Entrar/salir desde la interfaz (recarga providers, navega).
lib/core/widgets/
  demo_banner.dart    El aviso permanente y la salida.
```

`demo_dataset.dart` no toca nada de fuera, y por eso se puede comprobar entero
desde una prueba unitaria. `test/core/demo/` vigila lo que estas piezas rompen
con facilidad: que los valores sean posibles, que las familias no se contradigan
(el IMC sale del peso y la talla, el VLDL de los triglicéridos, los kg de músculo
del peso de ese día), que el resultado no cambie entre ejecuciones, que la
siembra siga encajando con lo que leen los providers, y que la vuelta atrás no
pierda el tipo de una preferencia — JSON no distingue un `int` de un `double`
entero, y `SharedPreferences` sí.

```sh
flutter test test/core/demo/
```

## Sobre la cuenta obligatoria

La cuenta sigue siendo obligatoria **para usar** la app. Esta tercera vía no es
el antiguo «explorar sin cuenta» que se eliminó: aquélla dejaba llevar mediciones
propias sin registrarse, ésta abre la historia de alguien que no existe, marcada
como tal con un aviso que no se puede cerrar y borrada al salir. Es un escaparate,
no un modo de uso.

## Límites conocidos

Dos cosas que la siembra **no** puede arreglar, porque no dependen de los datos:

- **Las gráficas dibujan como mucho 6 puntos** (`recentRecords` en los cuatro
  `*_history_tab.dart`), sea cual sea el filtro y el volumen de datos. En la
  analítica, que es trimestral, esos 6 puntos cubren 15 meses y la gráfica se lee
  perfecta; en tensión o peso cubren dos semanas, así que el filtro «Siempre»
  enseña una línea plana reciente en vez de la mejora de dos años.
- **La tarjeta de «Progreso de Autocuidado» está escrita a mano** en
  `profile_screen.dart`: nivel 1, barra al 15 % y medallas bloqueadas fijas. No se
  calcula desde los registros, así que un visitante que acaba de ver dos años de
  historia sigue apareciendo como principiante.

Las dos son anteriores a la demo y afectan también a la app real.
