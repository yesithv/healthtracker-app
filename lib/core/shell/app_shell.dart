import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
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

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRegisterModal(context),
        backgroundColor: const Color(0xFF0D48A0),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
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
                        color: const Color(0xFF0D48A0).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
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
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D48A0),
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
    final color = isSelected ? const Color(0xFF0D48A0) : Colors.grey[400];
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
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
