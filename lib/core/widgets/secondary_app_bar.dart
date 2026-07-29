import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'app_brand_header.dart';

class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final String? title;

  const SecondaryAppBar({super.key, this.onBack, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(100); // 70 + SafeArea (approx)

  @override
  Widget build(BuildContext context) {
    // El fondo llevaba el azul de «Pulso Clínico» escrito a mano, así que en
    // «Consulta Serena» la cabecera se quedaba azul mientras el resto de la
    // pantalla era cálido. El contenido (AppBrandHeader) ya usaba `onBrand`,
    // que es el par del token: solo faltaba pedir el otro lado.
    final surfaces = Theme.of(context).surfaces;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaces.brand,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(surfaces.radiusCard),
          bottomRight: Radius.circular(surfaces.radiusCard),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70, // Matches MainAppBar content height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Back Button on the left
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: surfaces.onBrand,
                    size: 20,
                  ),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                ),
              ),
              // App Brand Header or Custom Title centered
              Align(
                alignment: Alignment.center,
                child: title != null
                    ? AppBrandHeader(title: title!, subtitle: null)
                    : const AppBrandHeader(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
