part of 'record_body_composition_screen.dart';

// Piezas presentacionales de la hoja de registro de composición corporal. Viven
// en la MISMA librería (`part of`), así siguen siendo privadas de esta pantalla.
// Ninguna toca el estado del formulario: leen el tema y su familia de matiz del
// propio `context` y reciben por parámetro lo que pintan, de modo que sacarlas
// del `State` sólo aligera el archivo principal sin cambiar comportamiento.

/// Familia de matiz de «composición corporal», derivada del tema activo. Se
/// recalcula en cada `build` porque el color cambia con el tema, no con los datos.
Tone _bodyCompositionFamily(BuildContext context) =>
    Theme.of(context).metrics.tone(MetricFamily.bodyComposition);

/// Cabecera con el color de la familia, título centrado y volver.
class _BodyCompositionAppBar extends StatelessWidget {
  const _BodyCompositionAppBar(this.l10n);
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family = _bodyCompositionFamily(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: family.accent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(theme.surfaces.radiusCard + 4),
          bottomRight: Radius.circular(theme.surfaces.radiusCard + 4),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: family.onAccent),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  l10n.compositionTitle,
                  textAlign: TextAlign.center,
                  style: theme.type.sectionLabel.copyWith(
                    fontSize: 15,
                    color: family.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.accessibility_new, color: family.onAccent),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de sección: título (con icono/insignia opcionales) y su contenido.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.icon,
    required this.title,
    this.badge,
    required this.child,
  });
  final IconData? icon;
  final String title;
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family = _bodyCompositionFamily(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: theme.surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: family.accent, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.type.sectionLabel.copyWith(
                    color: theme.surfaces.ink,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Botones de ajuste ───────────────────────────────────────────────────────

/// Botón grande de ajuste sobre el acento de la familia (usado en el editor BMR).
class _BmrAdjustButton extends StatelessWidget {
  const _BmrAdjustButton(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = _bodyCompositionFamily(context).onAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: theme.surfaces.iconRadius,
      child: IconBadge(
        icon,
        color: onAccent,
        background: onAccent.withValues(alpha: 0.15),
        size: 32,
        iconSize: 16,
      ),
    );
  }
}

/// Botón de ajuste con borde, sobre el hueco (usado en los deslizadores).
class _AdjustButton extends StatelessWidget {
  const _AdjustButton(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final family = _bodyCompositionFamily(context);
    return InkWell(
      onTap: onTap,
      borderRadius: surfaces.iconRadius,
      child: IconBadge(
        icon,
        color: family.accent,
        background: surfaces.inset,
        size: 40,
        border: Border.all(color: surfaces.divider),
      ),
    );
  }
}

/// Botón de ajuste compacto (usado en los selectores de entero).
class _SmallAdjustButton extends StatelessWidget {
  const _SmallAdjustButton(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family = _bodyCompositionFamily(context);
    return InkWell(
      onTap: onTap,
      borderRadius: theme.surfaces.iconRadius,
      child: IconBadge(
        icon,
        color: family.accent,
        background: family.surface,
        size: 32,
        iconSize: 16,
      ),
    );
  }
}

/// Caja de comentario libre, acotada por [InputRules.freeText].
class _CommentBox extends StatelessWidget {
  const _CommentBox(this.controller, this.l10n);
  final TextEditingController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.inset,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.divider),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        // Texto libre, pero acotado: un pegado accidental no debe meter miles
        // de caracteres en la base.
        inputFormatters: InputRules.freeText(),
        style: theme.type.body.copyWith(color: surfaces.ink),
        decoration: InputDecoration(
          hintText: l10n.commentHint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
