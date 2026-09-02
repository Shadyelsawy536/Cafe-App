import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'product_image.dart';
import 'quick_quantity_control.dart';

class MenuProductListTile extends StatelessWidget {
  const MenuProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final VoidCallback onTap;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${product.basePrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: 'product_image_${product.id}',
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    width: 92,
                    height: 92,
                    borderRadius: 16,
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: QuickQuantityControl(
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
