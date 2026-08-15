import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
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

  const SettingsPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Column(
      // Centrado como en SettingsPageLayout. El texto descriptivo ocupa el
      // ancho disponible, así que el bloque queda centrado aunque el padre
      // alinee su contenido a la izquierda (p. ej. Metas de salud).
      children: [
        // El ICONO es el mismo en todos los temas; sólo cambia su vestido.
        IconBadge(
          icon,
          color: surfaces.brand,
          background: surfaces.selection,
          size: 80,
          iconSize: 32,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.type.screenTitle,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.type.body,
        ),
      ],
    );
  }
}
