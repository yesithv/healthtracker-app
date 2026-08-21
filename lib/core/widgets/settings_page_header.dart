import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/tone.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

/// EL ENCABEZADO COMÚN de una pantalla de submenú: ícono redondo centrado,
/// título y descripción. Es el bloque que abre casi todas las pantallas de
/// Perfil, así que vive en un solo sitio y se reutiliza en todas partes.
///
/// `SettingsPageLayout` lo compone para las pantallas con botón «Guardar», y
/// las pantallas tipo hub (cuenta, dispositivo, metas, copia, ayuda) lo usan
/// directamente encima de su contenido, sin repetir el maquetado.
///
/// El [title] y la [description] llegan ya localizados por quien lo usa (igual
/// que en `SettingsPageLayout`), para no atar el widget a una clave concreta.
class SettingsPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  /// Acento DE ORIENTACIÓN de la sección. Cuando llega, el icono se pinta con el
  /// mismo color (y tinte de fondo) que tenía la fila del menú de Perfil que
  /// abrió esta pantalla, para que la navegación se sienta continua. Cuando es
  /// `null`, el icono usa el azul de marca por defecto (usos fuera de ajustes).
  final Tone? accent;

  const SettingsPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final accentColor = accent?.accent;

    return Column(
      // Centrado como en SettingsPageLayout. El texto descriptivo ocupa el
      // ancho disponible, así que el bloque queda centrado aunque el padre
      // alinee su contenido a la izquierda (p. ej. Metas de salud).
      children: [
        // El ICONO es el mismo en todos los temas; sólo cambia su vestido. Si
        // la sección trae acento de orientación, lo lleva puesto —mismo color y
        // tinte que su fila en Perfil—; si no, el azul de marca.
        IconBadge(
          icon,
          color: accentColor ?? surfaces.brand,
          background:
              accentColor?.withValues(alpha: 0.12) ?? surfaces.selection,
          size: 80,
          iconSize: 32,
        ),
        const SizedBox(height: 24),
        Text(title, textAlign: TextAlign.center, style: theme.type.screenTitle),
        const SizedBox(height: 12),
        Text(description, textAlign: TextAlign.center, style: theme.type.body),
      ],
    );
  }
}
