import 'package:flutter/material.dart';
import 'app_brand_header.dart';

class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final String? title;

  const SecondaryAppBar({super.key, this.onBack, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(100); // 70 + SafeArea (approx)

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
          height: 70, // Matches MainAppBar content height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Back Button on the left
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
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
