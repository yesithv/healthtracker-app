import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/ecg_trace.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// PORTADA — primera pantalla del flujo real, tras el arranque.
///
/// Logotipo con el electro animado, las tres características de la app y los dos
/// caminos de entrada. Recupera la portada que ya existía en el proyecto
/// (`onboarding_welcome_page.dart`), que era un fragmento de `PageView` sin
/// botones y había quedado huérfana: ninguna ruta la referenciaba, y por eso no
/// se veía. Aquí es una pantalla enrutable, vestida con los tokens del tema y
/// con las acciones conectadas.
///
/// Los dos caminos son los que ya existían, sin inventar nada:
///
///   · «Iniciar sesión» → `/identify`, el paso único que busca el identificador:
///     si hay historial en el legacy lo trae, y si no existe la cuenta manda al
///     registro. El usuario no se autoclasifica, lo resuelve el lookup.
///   · «Registrarse» → `/onboarding?mode=account`, que recoge los datos y crea
///     la cuenta al terminar el asistente.
///
/// El enlace de explorar sin cuenta se mantiene porque el modo local es una
/// función existente: sin él quedaría inalcanzable desde el arranque.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entryController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
      );

  @override
  void initState() {
    super.initState();
    // Un respiro antes de entrar, para que la animación se vea empezar.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surfaces.brand,
              Color.lerp(surfaces.brand, surfaces.onBrand, 0.14)!,
              surfaces.brand,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  // El bloque se centra cuando hay sitio y pasa a desplazarse
                  // cuando no lo hay —pantalla pequeña, o tipografía grande por
                  // accesibilidad—, en vez de dejar un hueco muerto arriba.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Menos el padding vertical del propio scroll.
                            minHeight: constraints.maxHeight - 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // El electro decide su acabado según el tema.
                              const EcgTrace(
                                width: 220,
                                bareHeight: 56,
                                framedHeight: 130,
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'MY VITALS',
                                textAlign: TextAlign.center,
                                style: theme.type.display.copyWith(
                                  color: surfaces.onBrand,
                                  fontSize: 34,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Filete de acento bajo el logotipo.
                              Container(
                                height: 2,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: surfaces.dataStroke,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.onboardingWelcomeSubtitle,
                                textAlign: TextAlign.center,
                                style: theme.type.displayMeta.copyWith(
                                  color: surfaces.onBrand.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── LAS TRES CARACTERÍSTICAS ─────────────────────
                              _FeatureCard(
                                icon: Icons.monitor_heart_outlined,
                                text: l10n.onboardingWelcomeFeature1,
                                delay: 0,
                              ),
                              const SizedBox(height: 12),
                              _FeatureCard(
                                icon: Icons.show_chart_rounded,
                                text: l10n.onboardingWelcomeFeature2,
                                delay: 100,
                              ),
                              const SizedBox(height: 12),
                              _FeatureCard(
                                icon: Icons.lock_outline,
                                text: l10n.onboardingWelcomeFeature3,
                                delay: 200,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── LOS DOS CAMINOS ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: surfaces.onBrand,
                              foregroundColor: surfaces.brand,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  surfaces.radiusControl,
                                ),
                              ),
                            ),
                            onPressed: () => context.go('/identify'),
                            child: Text(
                              l10n.introSignIn,
                              textAlign: TextAlign.center,
                              style: theme.type.button.copyWith(
                                fontSize: 16,
                                color: surfaces.brand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: surfaces.onBrand,
                              side: BorderSide(
                                color: surfaces.onBrand.withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  surfaces.radiusControl,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                context.go('/onboarding?mode=account'),
                            child: Text(
                              l10n.introRegister,
                              textAlign: TextAlign.center,
                              style: theme.type.button.copyWith(
                                fontSize: 16,
                                color: surfaces.onBrand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Escape terciario: el modo local sigue alcanzable.
                        TextButton(
                          onPressed: () =>
                              context.go('/onboarding?mode=offline'),
                          child: Text(
                            l10n.introExploreOffline,
                            textAlign: TextAlign.center,
                            style: theme.type.button.copyWith(
                              fontSize: 14,
                              color: surfaces.onBrand.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una de las tres características, con entrada escalonada.
class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.text,
    required this.delay,
  });

  final IconData icon;
  final String text;
  final int delay;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 400 + widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: surfaces.onBrand.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(surfaces.radiusControl),
          border: Border.all(color: surfaces.onBrand.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            // Los tres iconos comparten el mismo tratamiento: antes cada uno
            // llevaba un color suelto (rojo, verde, azul claro) que no era
            // semántico y chocaba con la paleta del tema.
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: surfaces.onBrand.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: surfaces.onBrand, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.text,
                style: theme.type.body.copyWith(
                  fontSize: 14,
                  color: surfaces.onBrand.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
