import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../theme/discover_palette.dart';

/// Horizontal, icon-led category filter. Works on stable category *keys* so the
/// selection logic never depends on translated labels.
class CategoryChips extends StatelessWidget {
  final List<String> categoryKeys;
  final String selectedKey;
  final String Function(String key) labelFor;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.categoryKeys,
    required this.selectedKey,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categoryKeys.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = categoryKeys[index];
          final isSelected = key == selectedKey;
          final accent =
              key == 'all' ? DiscoverPalette.brandOf(context) : DiscoverPalette.of(context, key).accent;

          return Material(
            color: isSelected ? accent : surfaces.card,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accent : surfaces.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      DiscoverPalette.chipIcon(key),
                      size: 16,
                      color: isSelected ? surfaces.onBrand : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labelFor(key),
                      style: theme.type.button.copyWith(
                        color: isSelected ? surfaces.onBrand : surfaces.ink,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
