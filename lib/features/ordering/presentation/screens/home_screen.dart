import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../models/cafe_location.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/product_image.dart';
import 'product_details_screen.dart';

/// Home is the discovery/marketing landing page — welcome message, search,
/// a featured promo banner, branch locations, and social links. The full
/// categorized catalog lives on the Menu tab; search here is for jumping
/// straight to a known product by name.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onExploreMenu});

  /// Lets "Discover more" jump to the Menu tab without this screen needing
  /// to know how the bottom nav is implemented.
  final VoidCallback? onExploreMenu;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = Theme.of(context);
        final name = controller.lastCustomerInfo?.name;
        final isSearching = _query.trim().isNotEmpty;
        final results = isSearching ? _searchProducts(controller.products, _query) : const <Product>[];

        return Scaffold(
          appBar: AppBar(title: const Text('Cafe')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  name == null || name.isEmpty ? 'Welcome ☕' : 'Welcome, $name ☕',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text('What are you craving today?', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search the menu…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _query = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isSearching)
                  _SearchResults(results: results, query: _query)
                else ...[
                  if (controller.promotion != null)
                    _PromoCard(promotion: controller.promotion!, onTap: widget.onExploreMenu),
                  const SizedBox(height: 32),
                  Text('Our Locations', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...controller.locations.map((location) => _LocationTile(location: location)),
                  const SizedBox(height: 32),
                  Text('Follow Us', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const _FollowUsRow(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Product> _searchProducts(List<Product> products, String query) {
    final normalized = query.trim().toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(normalized) ||
            p.description.toLowerCase().contains(normalized) ||
            p.category.toLowerCase().contains(normalized))
        .toList();
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.query});

  final List<Product> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No results for "$query"', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${results.length} result${results.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        ...results.map((product) => _SearchResultTile(product: product)),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        context.read<OrderingController>().beginConfiguring(product);
        Navigator.of(context).push(buildDetailsRoute(ProductDetailsScreen(product: product)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ProductImage(imageUrl: product.imageUrl, width: 52, height: 52, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14)),
                  Text(product.category, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(
              '€${product.basePrice.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promotion, this.onTap});

  final Promotion promotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(imageUrl: promotion.imageUrl),
              // White text here is deliberate regardless of app theme — this
              // sits on the promo photo's own dark gradient overlay, not on
              // the scaffold background.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promotion.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'Discover more',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location});

  final CafeLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  location.address,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _FollowUsRow extends StatelessWidget {
  const _FollowUsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Icons only for now — wiring real profile links is a small addition
    // (the `url_launcher` package) once you have actual social accounts to
    // point to and have added the platform config it needs.
    //
    // TikTok's brand color is monochrome (black/white), so unlike
    // Instagram/Facebook's fixed brand colors, it needs to flip with the
    // theme to stay visible — hence onSurface instead of a literal color.
    final platforms = [
      (label: 'Instagram', icon: Icons.camera_alt_outlined, color: const Color(0xFFE1306C)),
      (label: 'Facebook', icon: Icons.facebook, color: const Color(0xFF1877F2)),
      (label: 'TikTok', icon: Icons.music_note, color: theme.colorScheme.onSurface),
    ];

    return Row(
      children: platforms
          .map(
            (platform) => Expanded(
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Follow us on ${platform.label}')),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: platform.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(platform.icon, color: platform.color),
                      const SizedBox(height: 6),
                      Text(
                        platform.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: platform.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
