import 'package:flutter/material.dart';

class AppBrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;

  const AppBrandHeader({
    super.key,
    this.title = 'MY VITALS',
    this.subtitle = 'Health Tracker',
    this.iconSize = 28,
    this.titleFontSize = 16,
    this.subtitleFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monitor_heart, color: Colors.white, size: iconSize),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                letterSpacing: 1.2,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: subtitleFontSize,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
