import 'package:flutter/material.dart';

import 'theme_context.dart';
import 'tokens/tone.dart';

/// LAS FILAS DE AJUSTES de Perfil y su acento DE ORIENTACIÓN.
///
/// Cada fila del menú de Perfil abre una pantalla de detalle. El cuadradito de
/// color del icono es lo que permite volver a encontrar «Idioma» sin leer las
/// once filas: es orientación, no semántica —un ajuste no está «óptimo» ni
/// pertenece a una familia de indicador—, así que el acento no puede salir de
/// la paleta clínica ni de la de métricas.
///
/// Sale de la paleta de CONTENIDO (más `surfaces.brand` y `clinical.neutral`)
/// porque es el único juego de acentos que el tema ya garantiza mutuamente
/// distinguible en matiz y legible en cualquier tema. Son 8 matices para 11
/// filas, así que tres se reutilizan, siempre en filas NO ADYACENTES: la lista
/// se ve variada y ninguna pareja de vecinas comparte color.
///
/// Vive aquí, en un solo sitio, para que la fila del menú ([_MenuTile] en
/// `profile_screen.dart`) y el encabezado de la pantalla de detalle
/// ([SettingsPageHeader]) lean EL MISMO tono y no puedan divergir: abrir una
/// fila lleva su color adentro.
enum SettingsSection {
  accountSync,
  personalInfo,
  device,
  healthGoals,
  medications,
  appTheme,
  language,
  measurementUnits,
  reminders,
  privacy,
  backup,
  help,
}

extension SettingsSectionAccent on SettingsSection {
  /// Tono de orientación de la sección, resuelto por el tema activo.
  Tone tone(ThemeData theme) => switch (this) {
    SettingsSection.accountSync => Tone.from(
      theme.surfaces.brand,
      canvas: theme.surfaces.card,
    ),
    SettingsSection.personalInfo => theme.content.sleep,
    SettingsSection.device => theme.content.daily,
    SettingsSection.healthGoals => theme.content.heart,
    // Medicamentos entra entre Metas (corazón) y Tema (emocional); toma el
    // matiz de «deporte» para no repetir el color de ninguna fila vecina.
    SettingsSection.medications => theme.content.sports,
    SettingsSection.appTheme => theme.content.emotional,
    SettingsSection.language => theme.content.nutrition,
    SettingsSection.measurementUnits => theme.content.sports,
    SettingsSection.reminders => theme.content.daily,
    SettingsSection.privacy => theme.content.nutrition,
    SettingsSection.backup => theme.content.sleep,
    SettingsSection.help => theme.clinical.neutral,
  };
}
