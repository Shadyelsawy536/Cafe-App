import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/animated_action_button.dart';
import '../widgets/modifier_group_section.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/size_selector.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final theme = Theme.of(context);
        final unitPrice = controller.currentUnitPrice(product);
        final total = controller.currentTotal(product);
        final currency = controller.settings.currency;

        return Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Center(
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      height: 240,
                      borderRadius: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(product.name, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(product.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                SizeSelector(
                  sizes: product.sizes,
                  selected: controller.selectedSize,
                  onSelected: controller.selectSize,
                ),
                if (product.sizes.isNotEmpty) const SizedBox(height: 20),
                for (final group in product.modifierGroups) ...[
                  ModifierGroupSection(
                    group: group,
                    selected: controller.selectedModifiersFor(group),
                    onToggle: (modifier) => controller.toggleModifier(group, modifier),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuantitySelector(
                      quantity: controller.quantity,
                      onIncrement: controller.incrementQuantity,
                      onDecrement: controller.decrementQuantity,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        CurrencyFormatter.format(total, currency),
                        key: ValueKey(total),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedActionButton(
                  status: _mapAddToCart(controller.addToCartStatus),
                  idleLabel: 'Add to cart · ${CurrencyFormatter.format(unitPrice, currency)}',
                  onPressed: () {
                    if (!controller.canAddToCart(product)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete the required selections above'),
                        ),
                      );
                      return;
                    }
                    controller.addToCart(product);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  ActionButtonStatus _mapAddToCart(AddToCartStatus status) {
    switch (status) {
      case AddToCartStatus.adding:
        return ActionButtonStatus.processing;
      case AddToCartStatus.added:
        return ActionButtonStatus.success;
      case AddToCartStatus.idle:
        return ActionButtonStatus.idle;
    }
  }
}
