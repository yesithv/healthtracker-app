import 'package:flutter/material.dart';

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
              key == 'all' ? DiscoverPalette.brand : DiscoverPalette.of(key).accent;

          return Material(
            color: isSelected ? accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accent : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      DiscoverPalette.chipIcon(key),
                      size: 16,
                      color: isSelected ? Colors.white : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labelFor(key),
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
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
