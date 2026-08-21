part of 'profile_screen.dart';

// Piezas del Perfil: la insignia de logro, la fila de menú y el botón de salir
// de la demo. Son StatelessWidget/StatefulWidget privados de la pantalla; viven
// en el mismo library (`part of`) y sólo se separan para aligerar el archivo
// principal, que se queda con la pantalla, el avatar y su hoja de imagen.

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  /// Tono ya resuelto por el tema. Recibe el tono y no un color para que el
  /// halo, el filete y el icono no puedan salir de sitios distintos.
  final Tone tone;
  final bool isLocked;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.tone,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final color = tone.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked
                    ? surfaces.inset
                    : color.withValues(alpha: 0.12),
                // Caja de icono: cuadrado redondeado del tema. No usa
                // `IconBadge` porque la insignia bloqueada envuelve su icono en
                // un `ColorFiltered`, y el widget sólo recibe un `IconData`.
                borderRadius: surfaces.iconRadius,
                border: Border.all(
                  color: isLocked
                      ? surfaces.divider
                      : color.withValues(alpha: 0.3),
                  width: 2,
                ),
                // Una insignia bloqueada no brilla; una ganada sí, salvo en
                // los temas planos, que es lo que decide `glow`.
                boxShadow: isLocked
                    ? const []
                    : surfaces.glow(color, alpha: 0.2, blur: 10),
              ),
              child: isLocked
                  ? const ColorFiltered(
                      colorFilter: ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Icon(Icons.lock_outline, size: 24),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.type.cardTitle.copyWith(
            fontSize: 11,
            color: isLocked ? surfaces.inkMuted : surfaces.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.type.meta.copyWith(
            fontSize: 9,
            fontWeight: isLocked ? FontWeight.normal : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Acento de orientación de la fila. Ver la nota en [ProfileScreen].
  final Tone tone;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = surfaces.radiusCard;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaces.selection,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tone.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tone.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.type.cardTitle.copyWith(
                        fontSize: 15,
                        color: surfaces.brand,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: surfaces.brand, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Salida de la demostración, con el mismo peso visual que tenía el cierre de
/// sesión: es la acción que saca al visitante de aquí, y tiene que encontrarse
/// igual de rápido.
///
/// No pide confirmación, y a diferencia del cierre de sesión no va en rojo. Lo
/// que se descarta son datos de un paciente que no existe, así que no hay nada
/// destructivo que advertir: gastar el rojo de ALERTA aquí le quitaría fuerza
/// donde sí significa algo, y un diálogo de confirmación sólo estorbaría el
/// camino hacia el registro, que es a donde esto lleva.
class _ExitDemoButton extends StatefulWidget {
  const _ExitDemoButton();

  @override
  State<_ExitDemoButton> createState() => _ExitDemoButtonState();
}

class _ExitDemoButtonState extends State<_ExitDemoButton> {
  bool _leaving = false;

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await exitDemo(context);
    if (mounted) setState(() => _leaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final tone = theme.clinical.info;

    return GestureDetector(
      onTap: _leaving ? null : _leave,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: surfaces.card,
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          border: Border.all(
            color: tone.accent.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: tone.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              l10n.demoExit,
              style: theme.type.button.copyWith(
                color: tone.accent,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
