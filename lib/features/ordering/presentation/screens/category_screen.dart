import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/ordering_controller.dart';
import '../controllers/ordering_controller_ui_state.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_showcase.dart';

/// Opened from a Home category tile. A persistent category tab bar up top
/// lets the customer switch between categories without backing out to
/// Home, and the showcase below is one swipeable widget (see
/// ProductShowcase) rather than a static hero next to an easy-to-miss
/// carousel strip.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late String _activeCategory;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final categories = controller.categories;
        final products =
            controller.products.where((p) => p.category == _activeCategory).toList();

        return Scaffold(
          appBar: AppBar(title: Text(_activeCategory)),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories
                        .map(
                          (category) => CategoryChip(
                            label: category,
                            isSelected: category == _activeCategory,
                            onTap: () => _switchCategory(controller, category),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('No items in this category yet'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ProductShowcase(
                            key: ValueKey(_activeCategory),
                            products: products,
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

  void _switchCategory(OrderingController controller, String category) {
    if (category == _activeCategory) return;
    setState(() => _activeCategory = category);
    controller.enterCategory(category);
  }
}
