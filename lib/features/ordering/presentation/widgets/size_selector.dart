import 'package:flutter/material.dart';

import '../../models/product_size.dart';

class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductSize> sizes;
  final ProductSize? selected;
  final ValueChanged<ProductSize> onSelected;

  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Row(
      children: sizes.map((size) {
        final isSelected = selected?.id == size.id;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelected(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                size.label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
