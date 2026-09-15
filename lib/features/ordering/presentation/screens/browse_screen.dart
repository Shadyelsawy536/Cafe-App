import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../models/experience_settings.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../controllers/ordering_controller_ui_state.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_list_tile.dart';
import 'product_details_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final categories = controller.categories;
        final products = controller.filteredProducts;

        return Scaffold(
          appBar: AppBar(title: const Text('Menu')),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _CategoryChip(
                        label: 'All',
                        isSelected: controller.selectedCategory == null,
                        onTap: () => controller.setCategory(null),
                      ),
                      ...categories.map(
                        (category) => _CategoryChip(
                          label: category,
                          isSelected: controller.selectedCategory == category,
                          onTap: () => controller.setCategory(category),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: controller.settings.browseLayout == BrowseLayout.grid
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) => ProductGridCard(
                            product: products[index],
                            onTap: () =>
                                _openDetails(context, controller, products[index]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: products.length,
                          itemBuilder: (context, index) => ProductListTile(
                            product: products[index],
                            onTap: () =>
                                _openDetails(context, controller, products[index]),
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

  void _openDetails(
    BuildContext context,
    OrderingController controller,
    Product product,
  ) {
    controller.beginConfiguring(product);
    Navigator.of(context).push(
      buildDetailsRoute(ProductDetailsScreen(product: product)),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black87 : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSelected ? Colors.black87 : Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
