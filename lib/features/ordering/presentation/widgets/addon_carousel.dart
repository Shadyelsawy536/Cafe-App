import 'package:flutter/material.dart';

import '../../models/addon.dart';
import 'product_image.dart';

class AddonCarousel extends StatelessWidget {
  const AddonCarousel({
    super.key,
    required this.addons,
    required this.selected,
    required this.onToggle,
  });

  final List<Addon> addons;
  final Set<Addon> selected;
  final ValueChanged<Addon> onToggle;

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: addons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final addon = addons[index];
          final isSelected = selected.contains(addon);

          return GestureDetector(
            onTap: () => onToggle(addon),
            child: AnimatedScale(
              scale: isSelected ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 96,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected ? Colors.black87 : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.black12,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProductImage(
                      imageUrl: addon.imageUrl,
                      width: 70,
                      height: 55,
                      borderRadius: 12,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      addon.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '+€${addon.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.black45,
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
