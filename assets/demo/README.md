# Avatar de la demo

La usuaria de la demostración (Camila Herrera) usa como foto de perfil, por orden
de preferencia:

1. **Una foto real** en `assets/demo/demo_avatar.jpg` — si ese archivo existe en el
   bundle, se usa tal cual.
2. **Un retrato ilustrado** dibujado por código en
   `lib/core/demo/demo_seeder.dart` (`DemoSeeder.illustratedAvatar`) — no retrata a
   nadie real y sale idéntico en cada arranque.
3. **Un monograma** con las iniciales, como última red.

## Poner una foto real

Basta con dejar caer aquí un `demo_avatar.jpg` **cuadrado** (recomendado ~400×400,
comprimido para pesar poco) y volver a compilar. No hay que tocar código: la ruta la
lee `DemoSeeder.avatarAssetPath`.

Usa solo imágenes con **licencia libre** (p. ej. Unsplash o Pexels, o Wikimedia
Commons con licencia CC) y anota aquí la fuente:

```
Fuente:      <URL de la foto>
Autor/a:     <nombre del/de la fotógrafo/a>
Licencia:    <p. ej. Unsplash License / Pexels License / CC BY 4.0>
```

> Nota: en el entorno donde se preparó este cambio, la política de red de la
> organización bloquea el acceso saliente a los bancos de imágenes, así que la
> demo se entrega con el **retrato ilustrado** como avatar por defecto. Añadir el
> `demo_avatar.jpg` desde un entorno con acceso lo sustituye automáticamente.
