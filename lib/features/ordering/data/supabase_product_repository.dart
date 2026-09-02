import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/tenant_config.dart';
import '../models/branding.dart';
import '../models/cafe_location.dart';
import '../models/experience_settings.dart';
import '../models/modifier.dart';
import '../models/modifier_group.dart';
import '../models/product.dart';
import '../models/product_size.dart';
import '../models/promotion.dart';
import 'product_repository.dart';

/// Real backend implementation — same interface as MockProductRepository,
/// so no screen or widget needed to change when this replaced it in
/// main.dart. Scoped entirely to [TenantConfig.restaurantId] since this
/// app is single-tenant for now.
class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select('''
          id, name, description, base_price, image_url, status, sort_order,
          categories(name),
          product_variants(id, label, price_delta, sort_order),
          product_modifier_groups(
            sort_order,
            modifier_groups(
              id, name, min_select, max_select, required,
              modifiers(id, name, price, image_url, sort_order)
            )
          )
        ''')
        .eq('restaurant_id', TenantConfig.restaurantId)
        .order('sort_order');

    return (rows as List<dynamic>).map<Product>((row) {
      final variantsRaw = List<Map<String, dynamic>>.from(row['product_variants'] as List)
        ..sort((a, b) => (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
      final sizes = variantsRaw
          .map((v) => ProductSize(
                id: v['id'] as String,
                label: v['label'] as String,
                priceDelta: (v['price_delta'] as num).toDouble(),
              ))
          .toList();

      final pmgRaw = List<Map<String, dynamic>>.from(row['product_modifier_groups'] as List)
        ..sort((a, b) => (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
      final modifierGroups = pmgRaw.map((pmg) {
        final g = pmg['modifier_groups'] as Map<String, dynamic>;
        final modifiersRaw = List<Map<String, dynamic>>.from(g['modifiers'] as List)
          ..sort((a, b) => (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
        return ModifierGroup(
          id: g['id'] as String,
          name: g['name'] as String,
          minSelect: g['min_select'] as int,
          maxSelect: g['max_select'] as int,
          required: g['required'] as bool,
          modifiers: modifiersRaw
              .map((m) => Modifier(
                    id: m['id'] as String,
                    name: m['name'] as String,
                    imageUrl: m['image_url'] as String? ?? '',
                    price: (m['price'] as num).toDouble(),
                  ))
              .toList(),
        );
      }).toList();

      return Product(
        id: row['id'] as String,
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        basePrice: (row['base_price'] as num).toDouble(),
        imageUrl: row['image_url'] as String? ?? '',
        category: (row['categories'] as Map<String, dynamic>?)?['name'] as String? ?? 'General',
        // Anything the client can fetch at all is either 'available' or
        // 'out_of_stock' — RLS already excludes 'hidden' products
        // entirely, so there's no separate branch needed for that case.
        available: row['status'] == 'available',
        sizes: sizes,
        modifierGroups: modifierGroups,
      );
    }).toList();
  }

  @override
  Future<Branding> fetchBranding() async {
    final row = await _client
        .from('restaurant_branding')
        .select('primary_color, secondary_color, background_color, font_family')
        .eq('restaurant_id', TenantConfig.restaurantId)
        .maybeSingle();

    if (row == null) return Branding.fallback;

    return Branding.fromJson({
      'primaryColor': row['primary_color'],
      'secondaryColor': row['secondary_color'],
      'backgroundColor': row['background_color'],
      'fontFamily': row['font_family'],
    });
  }

  @override
  Future<ExperienceSettings> fetchSettings() async {
    // No restaurant-configurable layout column exists yet — this becomes
    // real once the Dashboard's experience-config feature is built.
    return ExperienceSettings.fallback;
  }

  @override
  Future<Promotion> fetchPromotion() async {
    // No content-management table exists yet (see the audit — this maps
    // to spec §34, not yet built). Static placeholder until then.
    return const Promotion(
      title: 'Fresh Batch Brew, Daily',
      subtitle: 'Slow-brewed overnight for a smoother cup — try it iced.',
      imageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1000&q=80&auto=format&fit=crop',
    );
  }

  @override
  Future<List<CafeLocation>> fetchLocations() async {
    // Single-location tenant for now — derived directly from the
    // restaurants row rather than a separate branches table. Returns
    // empty if no address has been set yet (no fake data).
    final row = await _client
        .from('restaurants')
        .select('name, address')
        .eq('id', TenantConfig.restaurantId)
        .maybeSingle();

    final address = row?['address'] as String?;
    if (row == null || address == null || address.isEmpty) return [];

    return [CafeLocation(name: row['name'] as String, address: address)];
  }
}
