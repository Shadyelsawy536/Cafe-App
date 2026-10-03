import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/animated_action_button.dart';
import '../widgets/modifier_group_section.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/size_selector.dart';

class ProductDetailsScreen
    extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<ProductDetailsScreen>
      createState() =>
          _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  late Future<Product>
      _configurationFuture;

  @override
  void initState() {
    super.initState();

    final controller =
        context.read<OrderingController>();

    _configurationFuture =
        controller.loadProductConfiguration(
      widget.product,
    );
  }

  void _retryConfiguration() {
    final controller =
        context.read<OrderingController>();

    setState(() {
      _configurationFuture =
          controller.loadProductConfiguration(
        widget.product,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading:
            const BackButton(),
      ),
      body: FutureBuilder<Product>(
        future: _configurationFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ConfigurationError(
              onRetry:
                  _retryConfiguration,
            );
          }

          final product =
              snapshot.data;

          if (product == null) {
            return _ConfigurationError(
              onRetry:
                  _retryConfiguration,
            );
          }

          return _ProductDetailsContent(
            product: product,
          );
        },
      ),
    );
  }
}

class _ProductDetailsContent
    extends StatelessWidget {
  const _ProductDetailsContent({
    required this.product,
  });

  final Product product;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<OrderingController>(
      builder: (
        context,
        controller,
        _,
      ) {
        final theme =
            Theme.of(context);

        final unitPrice =
            controller.currentUnitPrice(
          product,
        );

        final total =
            controller.currentTotal(
          product,
        );

        final currency =
            controller.settings.currency;

        return SafeArea(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            children: [
              Center(
                child: Hero(
                  tag:
                      'product_image_${product.id}',
                  child: ProductImage(
                    imageUrl:
                        product.imageUrl,
                    height: 240,
                    borderRadius: 24,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                product.name,
                style: theme
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(
                height: 8,
              ),
              if (product
                  .description
                  .isNotEmpty)
                Text(
                  product.description,
                  style: theme
                      .textTheme
                      .bodyMedium,
                ),
              if (product
                  .description
                  .isNotEmpty)
                const SizedBox(
                  height: 20,
                ),
              if (product.sizes.isNotEmpty) ...[
                SizeSelector(
                  sizes:
                      product.sizes,
                  selected:
                      controller
                          .selectedSize,
                  onSelected:
                      controller
                          .selectSize,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
              for (
                final group
                    in product.modifierGroups
              ) ...[
                ModifierGroupSection(
                  group: group,
                  selected:
                      controller
                          .selectedModifiersFor(
                    group,
                  ),
                  onToggle:
                      (modifier) =>
                          controller
                              .toggleModifier(
                    group,
                    modifier,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  QuantitySelector(
                    quantity:
                        controller
                            .quantity,
                    onIncrement:
                        controller
                            .incrementQuantity,
                    onDecrement:
                        controller
                            .decrementQuantity,
                  ),
                  AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 300,
                    ),
                    transitionBuilder:
                        (
                      child,
                      animation,
                    ) =>
                            FadeTransition(
                      opacity:
                          animation,
                      child: child,
                    ),
                    child: Text(
                      CurrencyFormatter
                          .format(
                        total,
                        currency,
                      ),
                      key:
                          ValueKey(total),
                      style: theme
                          .textTheme
                          .titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              AnimatedActionButton(
                status:
                    _mapAddToCart(
                  controller
                      .addToCartStatus,
                ),
                idleLabel:
                    'Add to cart · '
                    '${CurrencyFormatter.format(unitPrice, currency)}',
                onPressed: () {
                  if (!controller
                      .canAddToCart(
                    product,
                  )) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please complete the required selections above',
                        ),
                      ),
                    );
                    return;
                  }

                  _addToCartInstantly(
                    controller,
                  );
                },
              ),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCartInstantly(
    OrderingController controller,
  ) {
    controller.addToCartStatus =
        AddToCartStatus.added;

    controller.cart.add(
      CartItem(
        id:
            '${product.id}_${DateTime.now().microsecondsSinceEpoch}',
        product: product,
        size:
            controller.selectedSize,
        modifiers:
            controller
                .selectedModifiers
                .values
                .expand(
                  (set) => set,
                )
                .toList(),
        quantity:
            controller.quantity,
      ),
    );

    controller.refreshUi();

    unawaited(
      Future<void>.delayed(
        const Duration(
          milliseconds: 300,
        ),
        () {
          controller.addToCartStatus =
              AddToCartStatus.idle;

          controller.refreshUi();
        },
      ),
    );
  }

  ActionButtonStatus _mapAddToCart(
    AddToCartStatus status,
  ) {
    switch (status) {
      case AddToCartStatus.adding:
        return ActionButtonStatus
            .processing;

      case AddToCartStatus.added:
        return ActionButtonStatus
            .success;

      case AddToCartStatus.idle:
        return ActionButtonStatus.idle;
    }
  }
}

class _ConfigurationError
    extends StatelessWidget {
  const _ConfigurationError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 48,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Could not load this product.',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}