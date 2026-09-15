import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../controllers/ordering_controller_ui_state.dart';
import '../screens/product_details_screen.dart';
import 'product_image.dart';

/// Center product is full-size and fully opaque; side products shrink and
/// fade — the parallax effect works for any product image, since it only
/// reads page-scroll position, never product content.
class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key, required this.products});
  final List<Product> products;
  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  late final PageController _pageController;
  @override
  void initState() { super.initState(); _pageController = PageController(viewportFraction: 0.72); }
  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OrderingController>();
    return SizedBox(
      height: 220,
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
              final scale = 1.0 - (distance * 0.25);
              final opacity = (1.0 - (distance * 0.6)).clamp(0.4, 1.0);
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
              child: _CarouselCard(product: product),
            ),
          );
        },
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Hero(
        tag: 'product_image_${product.id}',
        child: ProductImage(imageUrl: product.imageUrl, borderRadius: 20),
      ),
    );
  }
}
