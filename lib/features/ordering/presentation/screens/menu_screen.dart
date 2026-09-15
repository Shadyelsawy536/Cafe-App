import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../models/experience_settings.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/layout_toggle.dart';
import '../widgets/menu_product_card.dart';
import '../widgets/menu_product_list_tile.dart';
import 'product_details_screen.dart';

/// The full browsable catalog. Category chips stay pinned at the top;
/// tapping one scrolls to that section, and scrolling manually keeps the
/// chips in sync with whichever section is currently in view — the same
/// pattern most menu/food-delivery apps use.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _activeCategory;
  BrowseLayout _layout = BrowseLayout.grid;
  bool _layoutInitialized = false;

  static const double _chipRowHeight = 52;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveCategoryWithScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncActiveCategoryWithScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncActiveCategoryWithScroll() {
    final viewportBox = _viewportKey.currentContext?.findRenderObject();
    if (viewportBox is! RenderBox || !viewportBox.attached) return;

    String? best;
    double? bestTop;

    for (final entry in _sectionKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      // Position relative to the scrollable viewport itself, not the whole
      // screen — this is what was wrong before: comparing global screen
      // coordinates against a threshold that only accounted for the chip
      // row's height, ignoring the app bar/status bar above it, so the
      // condition almost never matched correctly while scrolling.
      final top = renderObject.localToGlobal(Offset.zero, ancestor: viewportBox).dy;

      // A section counts as "active" once its top has reached (or passed)
      // the top of the visible menu area; among those, pick the lowest one.
      if (top <= 20) {
        if (bestTop == null || top > bestTop) {
          best = entry.key;
          bestTop = top;
        }
      }
    }

    if (best != null && best != _activeCategory) {
      setState(() => _activeCategory = best);
    }
  }

  void _scrollToCategory(String category) {
    final context = _sectionKeys[category]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0,
    );
    setState(() => _activeCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        if (controller.loading || controller.products.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Adopt the dashboard-controlled default exactly once, the first
        // time data is available — after that, the customer's own toggle
        // choice wins for the rest of this session.
        if (!_layoutInitialized) {
          _layout = controller.settings.browseLayout;
          _layoutInitialized = true;
        }

        final categories = controller.categories;
        final activeCategory = _activeCategory ?? categories.first;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
            actions: [
              LayoutToggle(
                layout: _layout,
                onChanged: (layout) => setState(() => _layout = layout),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: _chipRowHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories
                        .map(
                          (category) => CategoryChip(
                            label: category,
                            isSelected: category == activeCategory,
                            onTap: () => _scrollToCategory(category),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: _viewportKey,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.map((category) {
                        final items =
                            controller.products.where((p) => p.category == category).toList();
                        final key = _sectionKeys.putIfAbsent(category, () => GlobalKey());

                        return Column(
                          key: key,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 15),
                                ),
                                const Spacer(),
                                Text(
                                  '${items.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _layout == BrowseLayout.grid
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.60,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final product = items[index];
                                      return MenuProductCard(
                                        product: product,
                                        onTap: () => _openDetails(context, controller, product),
                                        quantity: controller.quickAddQuantityFor(product),
                                        onIncrement: () => controller.incrementQuickAdd(product),
                                        onDecrement: () => controller.decrementQuickAdd(product),
                                      );
                                    },
                                  )
                                : Column(
                                    children: items
                                        .map(
                                          (product) => MenuProductListTile(
                                            product: product,
                                            onTap: () =>
                                                _openDetails(context, controller, product),
                                            quantity: controller.quickAddQuantityFor(product),
                                            onIncrement: () =>
                                                controller.incrementQuickAdd(product),
                                            onDecrement: () =>
                                                controller.decrementQuickAdd(product),
                                          ),
                                        )
                                        .toList(),
                                  ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, OrderingController controller, Product product) {
    controller.beginConfiguring(product);
    Navigator.of(context).push(buildDetailsRoute(ProductDetailsScreen(product: product)));
  }
}
