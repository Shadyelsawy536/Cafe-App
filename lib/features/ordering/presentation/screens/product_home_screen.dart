import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/ordering_controller.dart';
import '../widgets/product_carousel.dart';
import '../widgets/product_hero.dart';
import 'browse_screen.dart';
import 'cart_screen.dart';

class ProductHomeScreen extends StatelessWidget {
  const ProductHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        if (controller.loading || controller.products.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final products = controller.products;
        final current = products[controller.carouselIndex];
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cafe'),
            actions: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                tooltip: 'Menu',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BrowseScreen()),
                ),
              ),
              _CartIconButton(count: controller.cartCount),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                ProductHero(product: current),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    current.name,
                    key: ValueKey('name_${current.id}'),
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    '€${current.basePrice.toStringAsFixed(2)}',
                    key: ValueKey('price_${current.id}'),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 28),
                ProductCarousel(products: products),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
