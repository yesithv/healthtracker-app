import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens/tone.dart';

/// Una opción de la barra de chips: el valor que representa y su rótulo ya
/// localizado. El icono es opcional y refuerza la etiqueta para quien tiene
/// dificultad para leer texto pequeño o distinguir colores.
@immutable
class MetricChip<T> {
  const MetricChip({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Barra horizontal de chips para ELEGIR qué serie dibuja una gráfica.
///
/// Es el control con el que el historial de antropometría cambia entre IMC,
/// índices y perímetros, extraído aquí para que signos vitales, lípidos y
/// composición corporal muestren mañana el mismo gesto sin volver a inventarlo:
/// un mensaje arriba, un filtro de periodo y esta fila de chips que reparte la
/// misma gráfica entre varias métricas.
///
/// **Por qué el tamaño vive aquí y no en el tema.** El sistema de temas cambia
/// el ACABADO (color, sombra, redondeo), nunca la ESTRUCTURA: la maqueta es
/// idéntica entre temas a propósito. Por eso las medidas accesibles de un chip
/// —alto cómodo de tocar, texto legible, aire entre uno y otro— son constantes
/// de este widget, el único sitio donde se dibuja un chip de selección, y no
/// tokens que cada tema pudiera encoger. Antes se escribían a ojo en la pantalla
/// (alto 34, texto 12, muy pegados); ahora salen de un solo lugar y cumplen el
/// objetivo mínimo de zona táctil.
class MetricChipBar<T> extends StatelessWidget {
  const MetricChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.family,
  });

  final List<MetricChip<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Identidad de color de la familia del indicador (antropometría es ámbar,
  /// signos vitales rojo…). El chip elegido se rellena con su acento; el resto
  /// descansa en la superficie hundida del tema.
  final Tone family;

  /// Alto de la fila. Da holgura de zona táctil (recomendado ≥ 44 lógicos) sin
  /// que el control domine la pantalla.
  static const double _height = 44;

  /// Aire entre chips: lo bastante para que no se lean como un bloque.
  static const double _gap = 10;

  static const double _paddingH = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item.value == selected;
          final Color background = isSelected ? family.accent : surfaces.inset;
          final Color foreground = isSelected
              ? family.onAccent
              : surfaces.inkSecondary;

          return Semantics(
            button: true,
            selected: isSelected,
            label: item.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(item.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  // Alto explícito: en un ListView horizontal los hijos NO se
                  // estiran al alto del viewport, así que sin esto el chip
                  // mediría solo lo que el texto y la zona táctil se quedaría
                  // corta. Es la medida que defiende el test de accesibilidad.
                  height: _height,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: _paddingH),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? family.accent : surfaces.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.icon != null) ...[
                        Icon(item.icon, size: 16, color: foreground),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.label,
                        style: theme.type.button.copyWith(
                          fontSize: 14,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
