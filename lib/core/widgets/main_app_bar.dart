import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'app_brand_header.dart';

class MainAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MainAppBar({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final radius = Radius.circular(surfaces.radiusCard);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaces.brand,
        borderRadius: BorderRadius.only(
          bottomLeft: radius,
          bottomRight: radius,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70, // Fixed height for content area
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppBrandHeader(title: title, subtitle: subtitle),
        ),
      ),
    );
  }
}
