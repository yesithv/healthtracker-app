#!/usr/bin/env python3
"""Rehace `assets/fonts/NotoColorEmoji-Flags.ttf`.

Las banderas del selector de prefijo telefónico y del de idioma son emoji, no
imágenes: salen del código ISO del país. Mientras la app usaba las fuentes del
sistema las pintaba el sistema; al empaquetar las suyas se perdió ese respaldo y
las banderas pasaron a verse como cuadritos vacíos, porque ninguna de las cuatro
familias de texto trae emoji.

Noto Color Emoji entera pesa 10,8 MB. La app enseña 47 banderas. Este script
recorta la fuente a EXACTAMENTE esas 47 —unos 159 KB— leyendo el catálogo de
países del propio código, para que la fuente no pueda desviarse de él.

    python3 tool/subset_flag_font.py

Hace falta `fonttools` y la fuente completa. En Debian/Ubuntu:

    apt-get install fonts-noto-color-emoji
    pip install fonttools

Si se añade o se quita un país en `lib/core/constants/countries.dart`, hay que
volver a ejecutarlo. `test/core/l10n/flag_glyph_coverage_test.dart` falla si no
se hace, nombrando los países afectados.
"""

import os
import re
import sys

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOGUE = os.path.join(ROOT, 'lib/core/constants/countries.dart')
OUT = os.path.join(ROOT, 'assets/fonts/NotoColorEmoji-Flags.ttf')

SOURCES = [
    '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
    '/usr/local/share/fonts/NotoColorEmoji.ttf',
    os.path.expanduser('~/.fonts/NotoColorEmoji.ttf'),
]

# Primer «regional indicator symbol»: el que corresponde a la letra A.
RI_A = 0x1F1E6


def flag_of(iso):
    """`'CO'` → `'🇨🇴'`. Es la misma derivación que hace `Country.flag`."""
    return ''.join(chr(ord(c) - ord('A') + RI_A) for c in iso)


def main():
    source = next((p for p in SOURCES if os.path.exists(p)), None)
    if source is None:
        sys.exit(
            'No se encontró NotoColorEmoji.ttf. Instálala '
            '(apt-get install fonts-noto-color-emoji) o añade su ruta a '
            'SOURCES.'
        )

    isos = sorted(set(re.findall(r"Country\('([A-Z]{2})'", open(CATALOGUE).read())))
    if not isos:
        sys.exit(f'No se leyó ningún país de {CATALOGUE}.')
    wanted = {tuple(ord(c) for c in flag_of(iso)) for iso in isos}

    font = TTFont(source)
    cmap = font.getBestCmap()
    glyph_of_ri = {c: cmap[c] for c in range(RI_A, RI_A + 26) if c in cmap}
    ri_of_glyph = {v: k for k, v in glyph_of_ri.items()}

    # El recorte por puntos de código no basta: una bandera es una LIGADURA de
    # dos indicadores regionales, y el cierre de `pyftsubset` conservaría todas
    # las combinaciones posibles entre las letras que sobrevivan —unas 250
    # banderas en vez de 47—. Así que primero se podan a mano las ligaduras que
    # no se usan, y después se recorta.
    kept = set()
    for lookup in font['GSUB'].table.LookupList.Lookup:
        for st in lookup.SubTable:
            ligatures = getattr(st, 'ligatures', None)
            if not ligatures:
                continue
            for first, ligs in list(ligatures.items()):
                if first not in ri_of_glyph:
                    continue  # no es una bandera: se deja en paz
                keep = []
                for lig in ligs:
                    parts = [first] + list(lig.Component)
                    if not all(g in ri_of_glyph for g in parts):
                        keep.append(lig)
                        continue
                    seq = tuple(ri_of_glyph[g] for g in parts)
                    if seq in wanted:
                        keep.append(lig)
                        kept.add(seq)
                if keep:
                    ligatures[first] = keep
                else:
                    del ligatures[first]

    missing = wanted - kept
    if missing:
        names = ', '.join(
            ''.join(chr(c - RI_A + ord('A')) for c in seq) for seq in sorted(missing)
        )
        sys.exit(f'La fuente de origen no trae bandera para: {names}')

    options = Options()
    options.layout_features = ['*']
    options.notdef_outline = True
    subsetter = Subsetter(options=options)
    subsetter.populate(text=''.join(flag_of(iso) for iso in isos))
    subsetter.subset(font)
    font.save(OUT)

    size = os.path.getsize(OUT) / 1024
    print(f'{len(isos)} banderas · {size:.1f} KB · {OUT}')


if __name__ == '__main__':
    main()
