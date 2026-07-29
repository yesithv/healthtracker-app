import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../widgets/register_modal.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/discover')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Default: dashboard
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRegisterModal(context),
        backgroundColor: surfaces.brand,
        // Los temas planos no levantan el botón del lienzo.
        elevation: surfaces.cardShadow.isEmpty ? 0 : 4,
        shape: const CircleBorder(),
        // El icono no cambia: sólo su color se adapta al fondo de marca.
        child: Icon(Icons.add, color: surfaces.onBrand, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: surfaces.card,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 75,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 5;
              return Stack(
                children: [
                  // Sliding Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    left: itemWidth * currentIndex,
                    top: 8,
                    bottom: 8,
                    width: itemWidth,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: surfaces.selection,
                        borderRadius: BorderRadius.circular(
                          surfaces.radiusControl,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavBarItem(
                        icon: Icons.home,
                        label: l10n.dashboard.toUpperCase(),
                        isSelected: currentIndex == 0,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _NavBarItem(
                        icon: Icons.bar_chart,
                        label: l10n.history.toUpperCase(),
                        isSelected: currentIndex == 1,
                        onTap: () => context.go('/history'),
                      ),
                      // Central spacer for the FAB
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24), // Space for the FAB
                            Text(
                              l10n.record.toUpperCase(),
                              style: theme.type.badge.copyWith(
                                fontSize: 10,
                                color: surfaces.brand,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NavBarItem(
                        icon: Icons.explore,
                        label: l10n.discover.toUpperCase(),
                        isSelected: currentIndex == 3,
                        onTap: () => context.go('/discover'),
                      ),
                      _NavBarItem(
                        icon: Icons.person,
                        label: l10n.profile.toUpperCase(),
                        isSelected: currentIndex == 4,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Sobre el realce, el contenido va en `onSelection`: es el otro lado del
    // par, y el contrato garantiza que se lea en cualquier tema.
    final color = isSelected ? surfaces.onSelection : surfaces.inkMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.type.badge.copyWith(
                color: color,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
