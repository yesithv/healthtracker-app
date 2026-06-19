import 'package:flutter/material.dart';
import 'app_brand_header.dart';

class MainAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MainAppBar({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0D48A0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
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
