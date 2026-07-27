import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';

/// A wrapper screen that displays a history category tab widget
/// with the app's secondary app bar and back navigation.
class HistoryCategoryScreen extends StatelessWidget {
  final Widget child;

  const HistoryCategoryScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).surfaces.canvas,
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
