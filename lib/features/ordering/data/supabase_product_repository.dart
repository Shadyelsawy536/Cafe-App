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

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _client.from('products').select('''
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
        ''').eq('restaurant_id', TenantConfig.restaurantId).order('sort_order');

    return (rows as List<dynamic>).map<Product>((row) {
      final variantsRaw = List<Map<String, dynamic>>.from(row['product_variants'] as List)
        ..sort((a, b) => (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
      final sizes = variantsRaw.map((v) => ProductSize(
        id: v['id'] as String,
        label: v['label'] as String,
        priceDelta: (v['price_delta'] as num).toDouble(),
      )).toList();

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
          modifiers: modifiersRaw.map((m) => Modifier(
            id: m['id'] as String,
            name: m['name'] as String,
            imageUrl: m['image_url'] as String? ?? '',
            price: (m['price'] as num).toDouble(),
          )).toList(),
        );
      }).toList();

      return Product(
        id: row['id'] as String,
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        basePrice: (row['base_price'] as num).toDouble(),
        imageUrl: row['image_url'] as String? ?? '',
        category: (row['categories'] as Map<String, dynamic>?)?['name'] as String? ?? 'General',
        available: row['status'] == 'available',
        sizes: sizes,
        modifierGroups: modifierGroups,
      );
    }).toList();
  }

  @override
  Future<Branding> fetchBranding() async {
    final row = await _client.from('restaurant_branding').select('''
          primary_color, secondary_color, background_color, font_family,
          customer_primary_color, customer_secondary_color,
          customer_background_color, customer_logo_url, customer_cover_url
        ''').eq('restaurant_id', TenantConfig.restaurantId).maybeSingle();
    if (row == null) return Branding.fallback;
    return Branding.fromJson({
      'primaryColor': row['customer_primary_color'] ?? row['primary_color'],
      'secondaryColor': row['customer_secondary_color'] ?? row['secondary_color'],
      'backgroundColor': row['customer_background_color'] ?? row['background_color'],
      'logo': row['customer_logo_url'],
      'cover': row['customer_cover_url'],
      'fontFamily': row['font_family'],
    });
  }

  @override
  Future<ExperienceSettings> fetchSettings() async {
    final row = await _client.from('restaurant_settings').select('''
          currency, preparation_time_minutes, accepts_scheduled_orders,
          scheduled_order_max_days, customer_notes_enabled, operational_status,
          closure_message, accepts_delivery, accepts_pickup, min_order_amount,
          tax_rate, timezone, order_number_prefix
        ''').eq('restaurant_id', TenantConfig.restaurantId).maybeSingle();

    if (row == null) return ExperienceSettings.fallback;

    return ExperienceSettings.fromJson(row);
  }

  @override
  Future<Promotion> fetchPromotion() async => const Promotion(
    title: 'Fresh Batch Brew, Daily',
    subtitle: 'Slow-brewed overnight for a smoother cup — try it iced.',
    imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1000&q=80&auto=format&fit=crop',
  );

  @override
  Future<List<CafeLocation>> fetchLocations() async {
    final rows = await _client.from('restaurant_locations').select('''
          id, name, map_url, address, latitude, longitude, is_primary, sort_order
        ''').eq('restaurant_id', TenantConfig.restaurantId)
        .eq('is_active', true).order('sort_order');

    return (rows as List<dynamic>).map((row) => CafeLocation(
      name: row['name'] as String,
      address: row['address'] as String? ?? '',
      mapUrl: row['map_url'] as String? ?? '',
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
    )).toList();
  }
}
