import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/services/image_picker_service.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

class OnboardingAvatarPage extends StatefulWidget {
  const OnboardingAvatarPage({super.key});

  @override
  State<OnboardingAvatarPage> createState() => _OnboardingAvatarPageState();
}

class _OnboardingAvatarPageState extends State<OnboardingAvatarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final prefs = Provider.of<UserProfileProvider>(context, listen: false);
      final pickerService = ImagePickerService();
      final base64 = await pickerService.pickImageAsBase64(source);
      if (base64 != null && mounted) {
        await prefs.setProfileImage(base64);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);
    final hasImage =
        prefs.profileImageBase64 != null &&
        prefs.profileImageBase64!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // El lavado parte del realce del tema y se disuelve en el lienzo.
          // Antes eran dos mezclas al 10 % y al 5 % con la marca, así que en un
          // tema de marca clara el degradado no se veía.
          colors: [
            surfaces.selection,
            Color.lerp(surfaces.selection, surfaces.canvas, 0.5)!,
            surfaces.canvas,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Title
              Text(
                l10n.onboardingAvatarTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: surfaces.ink,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.onboardingAvatarSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: surfaces.inkSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // Avatar with pulse animation
              ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: () => _showImageOptions(context),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              surfaces.brand.withValues(alpha: 0.15),
                              surfaces.brand.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Avatar
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: hasImage
                                ? surfaces.brand
                                : surfaces.inkMuted,
                            width: 3,
                          ),
                          boxShadow: surfaces.glow(
                            surfaces.brand,
                            alpha: 0.15,
                            blur: 20,
                            offset: const Offset(0, 6),
                          ),
                        ),
                        child: ClipOval(
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      surfaces.brand,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                )
                              : _buildAvatarContent(prefs.profileImageBase64),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: surfaces.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: surfaces.glow(
                              surfaces.brand,
                              alpha: 0.4,
                              blur: 10,
                              offset: const Offset(0, 3),
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Action buttons
              _ActionButton(
                icon: Icons.photo_library_outlined,
                label: l10n.gallery,
                color: surfaces.brand,
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              const SizedBox(height: 14),
              _ActionButton(
                icon: Icons.camera_alt_outlined,
                label: l10n.camera,
                color: theme.clinical.optimal.accent,
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              if (hasImage) ...[
                const SizedBox(height: 14),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.deletePhoto,
                  color: theme.clinical.alert.accent,
                  onTap: () => Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  ).setProfileImage(null),
                ),
              ],

              const SizedBox(height: 32),

              // Success indicator
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.clinical.optimal.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.clinical.optimal.accent.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.clinical.optimal.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.profileImageTitle,
                        style: TextStyle(
                          color: theme.clinical.optimal.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String? base64) {
    final surfaces = Theme.of(context).surfaces;
    if (base64 != null && base64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64),
          fit: BoxFit.cover,
          width: 140,
          height: 140,
        );
      } catch (_) {}
    }
    return Container(
      color: surfaces.divider,
      child: Icon(Icons.person_rounded, size: 72, color: surfaces.inkMuted),
    );
  }

  void _showImageOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: surfaces.inkMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.profileImageTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: surfaces.ink,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: IconBadge(
                Icons.photo_library_outlined,
                color: surfaces.brand,
                background: surfaces.brand.withValues(alpha: 0.1),
                iconSize: 24,
              ),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: IconBadge(
                Icons.camera_alt_outlined,
                color: theme.clinical.optimal.accent,
                background: theme.clinical.optimal.accent.withValues(
                  alpha: 0.1,
                ),
                iconSize: 24,
              ),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: surfaces.card,
            borderRadius: BorderRadius.circular(surfaces.radiusControl),
            border: Border.all(
              color: Color.lerp(surfaces.card, color, 0.20)!,
              width: 1.5,
            ),
            boxShadow: surfaces.cardShadow,
          ),
          child: Row(
            children: [
              IconBadge(
                icon,
                color: color,
                background: Color.lerp(surfaces.card, color, 0.10)!,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: theme.type.button.copyWith(fontSize: 15, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
