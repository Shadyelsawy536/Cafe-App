import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../screens/product_details_screen.dart';
import 'product_image.dart';

/// The primary product showcase. This is deliberately ONE swipeable widget
/// rather than a static hero image sitting next to a separate carousel
/// strip — the previous split made it look like there was only one item,
/// since nothing about the big image itself hinted it was swipeable.
///
/// Here, neighboring products visibly peek in at both edges (scaled down
/// and faded), and dot indicators show how many items there are and which
/// one is active — both are standard, well-understood "swipe for more"
/// affordances.
class ProductShowcase extends StatefulWidget {
  const ProductShowcase({super.key, required this.products});

  final List<Product> products;

  @override
  State<ProductShowcase> createState() => _ProductShowcaseState();
}

class _ProductShowcaseState extends State<ProductShowcase> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<OrderingController>();
    final startIndex = _safeIndex(controller.carouselIndex, widget.products.length);
    _pageController = PageController(viewportFraction: 0.82, initialPage: startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _safeIndex(int index, int length) => index < length ? index : 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderingController>();
    final theme = Theme.of(context);
    final activeIndex = _safeIndex(controller.carouselIndex, widget.products.length);
    final current = widget.products[activeIndex];

    return Column(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.products.length,
            onPageChanged: controller.setCarouselIndex,
            itemBuilder: (context, index) {
              final product = widget.products[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = index.toDouble();
                  if (_pageController.position.haveDimensions) {
                    page = _pageController.page ?? _pageController.initialPage.toDouble();
                  }
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - (distance * 0.16); // center 1.0 -> side 0.84
                  final opacity = (1.0 - (distance * 0.55)).clamp(0.45, 1.0);

                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    controller.beginConfiguring(product);
                    Navigator.of(context).push(
                      buildDetailsRoute(ProductDetailsScreen(product: product)),
                    );
                  },
                  child: _ShowcaseCard(product: product),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            current.name,
            key: ValueKey('name_${current.id}'),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
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
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 14),
        if (widget.products.length > 1)
          _PageDots(count: widget.products.length, activeIndex: activeIndex),
      ],
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Hero(
        tag: 'product_image_${product.id}',
        child: ProductImage(imageUrl: product.imageUrl, borderRadius: 28),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
