import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../../../core/config/tenant_config.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/cafe_location.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../../models/restaurant_social_link.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/product_image.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onExploreMenu});

  final VoidCallback? onExploreMenu;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<RestaurantSocialLink> _socialLinks = const [];
  RealtimeChannel? _socialChannel;

  @override
  void initState() {
    super.initState();
    _loadSocialLinks();
    _subscribeToSocialLinks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    final channel = _socialChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _loadSocialLinks() async {
    try {
      final rows = await Supabase.instance.client
          .from('restaurant_social_links')
          .select('platform, label, url')
          .eq('restaurant_id', TenantConfig.restaurantId)
          .eq('is_active', true)
          .order('sort_order');
      if (!mounted) return;
      setState(() {
        _socialLinks = (rows as List<dynamic>)
            .map((row) => RestaurantSocialLink.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ))
            .where((link) => link.url.isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('SOCIAL LINKS: load failed: $e');
    }
  }

  void _subscribeToSocialLinks() {
    final channel = Supabase.instance.client.channel(
      'cafe-social-links-${TenantConfig.restaurantId}',
    );
    _socialChannel = channel;
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_social_links',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'restaurant_id',
        value: TenantConfig.restaurantId,
      ),
      callback: (_) => _loadSocialLinks(),
    );
    channel.subscribe((status, error) {
      debugPrint('SOCIAL LINKS REALTIME: $status${error == null ? '' : ' $error'}');
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This link is not valid.')),
      );
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    } catch (e) {
      debugPrint('URL LAUNCH: failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    }
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
        final results = isSearching
            ? _searchProducts(controller.products, _query)
            : const <Product>[];

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
                    _PromoCard(
                      promotion: controller.promotion!,
                      onTap: widget.onExploreMenu,
                    ),
                  const SizedBox(height: 32),
                  Text('Our Locations', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...controller.locations.map(
                    (location) => _LocationTile(
                      location: location,
                      onTap: location.hasMapLink ? () => _openUrl(location.mapUrl) : null,
                    ),
                  ),
                  if (controller.locations.isEmpty)
                    Text('No locations available.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  if (_socialLinks.isNotEmpty) ...[
                    Text('Follow Us', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _FollowUsRow(links: _socialLinks, onOpen: _openUrl),
                  ],
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
        .where((p) => p.name.toLowerCase().contains(normalized) ||
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
        child: Center(child: Text('No results for "$query"')),
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
    final currency = context.watch<OrderingController>().settings.currency;
    return GestureDetector(
      onTap: () {
        context.read<OrderingController>().beginConfiguring(product);
        Navigator.of(context).push(buildDetailsRoute(ProductDetailsScreen(product: product)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
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
              CurrencyFormatter.format(product.basePrice, currency),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(imageUrl: promotion.imageUrl),
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
                    Text(promotion.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(promotion.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Row(children: [Text('Discover more', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), SizedBox(width: 4), Icon(Icons.arrow_forward, color: Colors.white, size: 16)]),
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
  const _LocationTile({required this.location, this.onTap});
  final CafeLocation location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                    if (location.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(location.address, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (location.hasMapLink)
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUsRow extends StatelessWidget {
  const _FollowUsRow({required this.links, required this.onOpen});
  final List<RestaurantSocialLink> links;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: links.map((link) {
        final platform = link.platform.toLowerCase();
        final isInstagram = platform == 'instagram';
        final isFacebook = platform == 'facebook';
        final icon = isInstagram
            ? Icons.camera_alt_outlined
            : isFacebook
                ? Icons.facebook
                : Icons.music_note;
        final color = isInstagram
            ? const Color(0xFFE1306C)
            : isFacebook
                ? const Color(0xFF1877F2)
                : theme.colorScheme.onSurface;
        return Expanded(
          child: GestureDetector(
            onTap: () => onOpen(link.url),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 6),
                  Text(link.label.isEmpty ? _title(platform) : link.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _title(String platform) {
    if (platform.isEmpty) return 'Social';
    return '${platform[0].toUpperCase()}${platform.substring(1)}';
  }
}
