import 'package:flutter/material.dart';

import '../../../../core/theme/theme_catalog.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/widgets/status_chip.dart';

/// Ficha de un tema con su resumen visual: paleta, tipografía y componentes.
///
/// El truco está en que la ficha se dibuja DENTRO del tema que describe: el
/// contenido va envuelto en un [Theme] con la `ThemeData` de ese tema, así que
/// los mismos widgets que usa la app real se pintan aquí con sus tokens. No es
/// una maqueta que haya que mantener en paralelo — es la cosa real, en pequeño.
/// Si mañana cambia un token, esta ficha cambia con él y no puede mentir.
///
/// Es deliberadamente COMPACTA: cabe entera en pantalla junto a las demás, para
/// que elegir sea comparar de un vistazo y no recorrer una lista larga. Cada
/// pieza que sobrevive gana su sitio mostrando algo que las otras no:
///
/// - la **barra de paleta** — los ocho colores del tema, de un tirón;
/// - la **cifra** — donde más se nota el cambio de tipografía;
/// - el **botón** — la marca sobre su propio relleno, y el radio de control;
/// - la **tarjeta que los contiene** — plana o con sombra, según el tema;
/// - las **cuatro insignias** — que el significado no cambia aunque cambie el
///   acabado. Es la fila que justifica la pantalla entera.
///
/// Lo que se cayó al acortar —rótulos de panel, hexadecimales, botón secundario,
/// casilla de dato y conmutador segmentado— o repetía una señal ya presente, o
/// hablaba a un diseñador y no a quien está eligiendo cómo quiere ver su app.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.spec,
    required this.isSelected,
    required this.onSelect,
  });

  final AppThemeSpec spec;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final preview = spec.theme;
    final surfaces = preview.surfaces;

    return Theme(
      data: preview,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '${spec.name}. ${spec.tagline} ${spec.typeNote}',
        child: Container(
          decoration: BoxDecoration(
            color: surfaces.canvas,
            borderRadius: BorderRadius.circular(surfaces.radiusCard + 4),
            border: Border.all(
              color: isSelected ? surfaces.brand : surfaces.divider,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(spec: spec, isSelected: isSelected),
                    const SizedBox(height: 12),
                    // El muestrario es inerte: los botones y las insignias de
                    // ejemplo no deben capturar el toque que selecciona la ficha.
                    IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PaletteBar(id: spec.id),
                          const SizedBox(height: 12),
                          const _Sample(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CABECERA ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.spec, required this.isSelected});

  final AppThemeSpec spec;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.name,
                style: theme.type.screenTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 3),
              Text(
                spec.tagline,
                style: theme.type.body.copyWith(fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 2),
              // La nota tipográfica va aquí, no en un panel propio: es una línea
              // de texto, y darle rótulo y hueco costaba más alto que informar.
              Text(spec.typeNote, style: theme.type.meta),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Marca de selección: forma + color, nunca color a solas.
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? surfaces.brand : Colors.transparent,
            border: Border.all(
              color: isSelected ? surfaces.brand : surfaces.inkMuted,
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check_rounded, size: 14, color: surfaces.onBrand)
              : null,
        ),
      ],
    );
  }
}

// ── PALETA ────────────────────────────────────────────────────────────────────

/// Los colores del tema en una sola barra.
///
/// Antes era una rejilla de cuatro columnas con nombre y hexadecimal debajo de
/// cada muestra: tres líneas de alto por fila, dos filas, para decir algo que el
/// color ya dice solo. El hexadecimal servía a quien construye el tema, no a
/// quien lo elige — y quien lo construye lo tiene en `themes/*.dart`.
class _PaletteBar extends StatelessWidget {
  const _PaletteBar({required this.id});

  final AppThemeId id;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final swatches = AppThemeCatalog.swatchesOf(id);

    return Container(
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // Filete y separadores siempre: sin ellos, los tramos claros —«Lienzo»,
        // «Tarjeta»— se fundirían entre sí y con el fondo de la ficha.
        border: Border.all(color: surfaces.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final (i, s) in swatches.indexed)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: s.color,
                  border: i == 0
                      ? null
                      : Border(left: BorderSide(color: surfaces.divider)),
                ),
                // Sin hijo no hay nada que medir: el alto lo fija el Container y
                // el ancho lo reparte el Expanded.
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── MUESTRARIO ────────────────────────────────────────────────────────────────

/// Cifra, botón e insignias dentro de una tarjeta del propio tema.
///
/// Van juntos a propósito: la tarjeta que los contiene ya comunica si el tema
/// usa sombra o superficie plana, así que no hace falta una muestra aparte para
/// eso.
class _Sample extends StatelessWidget {
  const _Sample();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: surfaces.cardDecoration(radius: surfaces.radiusControl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // La cifra: el elemento donde más se nota el cambio de tema.
              Text(
                '68,4',
                style: theme.type.numeralSmall.copyWith(fontSize: 24),
              ),
              const SizedBox(width: 5),
              Padding(
                // Alinea la unidad con la base de la cifra sin pagar el coste de
                // una fila con línea de base, que aquí obligaría a más alto.
                padding: const EdgeInsets.only(top: 6),
                child: Text('kg', style: theme.type.numeralUnit),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: surfaces.brand,
                  borderRadius: BorderRadius.circular(surfaces.radiusControl),
                ),
                child: Text(
                  'Registrar',
                  style: theme.type.button.copyWith(
                    fontSize: 13,
                    color: surfaces.onBrand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Los cuatro estados clínicos, con el idioma de insignia del tema.
          // Es la fila más importante de la ficha: aquí se ve que el significado
          // de los colores no cambia aunque cambie el acabado.
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(status: ClinicalStatus.optimal, label: 'Óptimo'),
              StatusChip(status: ClinicalStatus.caution, label: 'Elevada'),
              StatusChip(status: ClinicalStatus.alert, label: 'Alto'),
              StatusChip(status: ClinicalStatus.info, label: 'Bajo'),
            ],
          ),
        ],
      ),
    );
  }
}
