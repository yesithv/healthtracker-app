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
        label: '${spec.name}. ${spec.tagline}',
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(spec: spec, isSelected: isSelected),
                    const SizedBox(height: 18),
                    // El muestrario es inerte: los botones y conmutadores de
                    // ejemplo no deben capturar el toque que selecciona la ficha.
                    IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PanelLabel('Paleta'),
                          const SizedBox(height: 10),
                          _PaletteGrid(id: spec.id),
                          const SizedBox(height: 20),
                          _PanelLabel('Tipografía'),
                          const SizedBox(height: 10),
                          _TypeSample(typeNote: spec.typeNote),
                          const SizedBox(height: 20),
                          _PanelLabel('Componentes'),
                          const SizedBox(height: 10),
                          const _ComponentSample(),
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
                style: theme.type.screenTitle.copyWith(fontSize: 21),
              ),
              const SizedBox(height: 6),
              Text(spec.tagline, style: theme.type.body.copyWith(fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Marca de selección: forma + color, nunca color a solas.
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? surfaces.brand : Colors.transparent,
            border: Border.all(
              color: isSelected ? surfaces.brand : surfaces.inkMuted,
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check_rounded, size: 16, color: surfaces.onBrand)
              : null,
        ),
      ],
    );
  }
}

/// Rótulo de panel, en el idioma de rótulos del propio tema.
class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: Theme.of(context).type.sectionLabel);
  }
}

// ── PALETA ────────────────────────────────────────────────────────────────────

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({required this.id});

  final AppThemeId id;

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final swatches = AppThemeCatalog.swatchesOf(id);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cuatro columnas, como la lámina del sistema de diseño. Se calcula el
        // ancho en vez de fijarlo para que la ficha aguante cualquier pantalla.
        const columns = 4;
        const gap = 10.0;
        final tile = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in swatches)
              SizedBox(
                width: tile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(10),
                        // Filete siempre: sin él, la muestra «Tarjeta» blanca
                        // desaparecería sobre un lienzo claro.
                        border: Border.all(color: surfaces.divider),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.type.numeralUnit.copyWith(fontSize: 10),
                    ),
                    Text(
                      _hex(s.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.type.numeralUnit.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── TIPOGRAFÍA ────────────────────────────────────────────────────────────────

class _TypeSample extends StatelessWidget {
  const _TypeSample({required this.typeNote});

  final String typeNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: surfaces.cardDecoration(radius: surfaces.radiusControl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La cifra: el elemento donde más se nota el cambio de tema.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('68,4', style: theme.type.numeral),
              const SizedBox(width: 6),
              Text('kg', style: theme.type.numeralUnit),
            ],
          ),
          const SizedBox(height: 10),
          Text('Registrar indicador', style: theme.type.button),
          const SizedBox(height: 8),
          Text(typeNote, style: theme.type.meta),
        ],
      ),
    );
  }
}

// ── COMPONENTES ───────────────────────────────────────────────────────────────

class _ComponentSample extends StatelessWidget {
  const _ComponentSample();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón primario.
        Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaces.brand,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
          ),
          child: Text(
            'Botón primario',
            style: theme.type.button.copyWith(color: surfaces.onBrand),
          ),
        ),
        const SizedBox(height: 10),
        // Botón secundario.
        Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaces.card,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(
              color: Color.lerp(surfaces.card, surfaces.brand, 0.28)!,
            ),
          ),
          child: Text(
            'Botón secundario',
            style: theme.type.button.copyWith(color: surfaces.ink),
          ),
        ),
        const SizedBox(height: 12),
        // Los cuatro estados clínicos, con el idioma de insignia del tema.
        // Es la fila más importante de la ficha: aquí se ve que el significado
        // de los colores no cambia aunque cambie el acabado.
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(status: ClinicalStatus.optimal, label: 'Óptimo'),
            StatusChip(status: ClinicalStatus.caution, label: 'Elevada'),
            StatusChip(status: ClinicalStatus.alert, label: 'Alto'),
            StatusChip(status: ClinicalStatus.info, label: 'Bajo'),
          ],
        ),
        const SizedBox(height: 12),
        // Casilla de dato.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: surfaces.inset,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PESO', style: theme.type.sectionLabel),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '68,4',
                    style: theme.type.numeralSmall.copyWith(fontSize: 26),
                  ),
                  const SizedBox(width: 6),
                  Text('kg', style: theme.type.numeralUnit),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Conmutador segmentado.
        Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: surfaces.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Métrico',
                  style: theme.type.badge.copyWith(
                    fontSize: 12.5,
                    color: surfaces.card,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  'Imperial',
                  style: theme.type.badge.copyWith(
                    fontSize: 12.5,
                    color: surfaces.inkSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
