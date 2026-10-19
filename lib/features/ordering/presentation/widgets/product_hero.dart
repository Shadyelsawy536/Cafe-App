import 'package:flutter/material.dart';

import '../../../../core/animations/animation_constants.dart';
import '../../models/product.dart';
import 'product_image.dart';

/// The large showcase image at the top of the home screen. Replays its
/// intro animation whenever the featured product changes (e.g. the
/// carousel below is swiped).
class ProductHero extends StatefulWidget {
  const ProductHero({super.key, required this.product});

  final Product product;

  @override
  State<ProductHero> createState() => _ProductHeroState();
}

class _ProductHeroState extends State<ProductHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.hero);
    final curved = CurvedAnimation(parent: _controller, curve: AppCurves.hero);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(curved);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _translateY = Tween<double>(begin: 40, end: 0).animate(curved);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProductHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: ProductImage(
        imageUrl: widget.product.imageUrl,
        height: 280,
        width: double.infinity,
        borderRadius: 24,
      ),
    );
  }
}
