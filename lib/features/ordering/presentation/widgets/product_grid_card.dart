import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'product_image.dart';

class ProductGridCard extends StatelessWidget {
  const ProductGridCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<OrderingController>().settings.currency;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Hero(tag: 'product_image_${product.id}', child: ProductImage(imageUrl: product.imageUrl, height: 120, width: double.infinity)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.format(product.basePrice, currency), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
