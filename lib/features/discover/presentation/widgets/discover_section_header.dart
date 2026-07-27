import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Section title row used across the Discover feed: an accent bar, the title and
/// an optional "See all" affordance.
class DiscoverSectionHeader extends StatelessWidget {
  final String title;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DiscoverSectionHeader({
    super.key,
    required this.title,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.type.screenTitle.copyWith(
                fontSize: 19,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: theme.type.button.copyWith(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
