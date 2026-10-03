import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import 'product_image.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<OrderingController>().settings.currency;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Row(children: [
              Hero(tag: 'product_image_${product.id}', child: ProductImage(imageUrl: product.imageUrl, width: 100, height: 100)),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(CurrencyFormatter.format(product.basePrice, currency), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
