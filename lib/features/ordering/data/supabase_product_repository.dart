import 'package:flutter/foundation.dart';
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
  SupabaseProductRepository();

  final SupabaseClient _client =
      Supabase.instance.client;

  /// Complete product configuration cache.
  ///
  /// Presence in this map means that the configuration
  /// has already been fetched successfully.
  final Map<String, Product>
      _productConfigurationCache = {};

  /// Prevents duplicate requests for the same product.
  final Map<String, Future<Product>>
      _configurationRequests = {};

  /// Used to prevent an invalidated in-flight request
  /// from putting stale data back into the cache.
  final Map<String, int>
      _configurationRequestGenerations = {};

  /// Reverse index:
  /// modifier group id -> cached product ids
  final Map<String, Set<String>>
      _productsByModifierGroup = {};

  /// Reverse index:
  /// modifier id -> cached product ids
  final Map<String, Set<String>>
      _productsByModifier = {};

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select('''
          id,
          name,
          description,
          base_price,
          image_url,
          status,
          sort_order,
          categories(name)
        ''')
        .eq(
          'restaurant_id',
          TenantConfig.restaurantId,
        )
        .order('sort_order');

    final products =
        (rows as List<dynamic>)
            .map<Product>((row) {
      final data =
          row as Map<String, dynamic>;

      return Product(
        id: data['id'] as String,
        name: data['name'] as String,
        description:
            data['description'] as String? ??
                '',
        basePrice:
            (data['base_price'] as num)
                .toDouble(),
        imageUrl:
            data['image_url'] as String? ??
                '',
        category:
            (data['categories']
                    as Map<String, dynamic>?)?['name']
                as String? ??
                'General',
        available:
            data['status'] == 'available',
      );
    }).toList();

    if (kDebugMode) {
      debugPrint(
        'PRODUCTS LOADED: ${products.length}',
      );
    }

    return products;
  }

  @override
  Product? getCachedProductConfiguration(
    String productId,
  ) {
    return _productConfigurationCache[
        productId];
  }

  @override
  Future<Product> fetchProductConfiguration(
    String productId,
  ) {
    final cached =
        _productConfigurationCache[productId];

    if (cached != null) {
      if (kDebugMode) {
        debugPrint(
          'CONFIG CACHE HIT: $productId',
        );
      }

      return Future<Product>.value(cached);
    }

    final existingRequest =
        _configurationRequests[productId];

    if (existingRequest != null) {
      if (kDebugMode) {
        debugPrint(
          'CONFIG REQUEST ALREADY RUNNING: '
          '$productId',
        );
      }

      return existingRequest;
    }

    final generation =
        (_configurationRequestGenerations[
                    productId] ??
                0) +
            1;

    _configurationRequestGenerations[
        productId] = generation;

    final request =
        _fetchProductConfigurationFromSupabase(
      productId,
    );

    _configurationRequests[productId] =
        request;

    request.then(
      (product) {
        final currentGeneration =
            _configurationRequestGenerations[
                productId];

        final isLatestRequest =
            currentGeneration ==
                generation;

        if (!isLatestRequest) {
          if (kDebugMode) {
            debugPrint(
              'STALE CONFIG REQUEST IGNORED: '
              '$productId',
            );
          }

          return;
        }

        _configurationRequests.remove(
          productId,
        );

        _cacheProductConfiguration(
          product,
        );

        if (kDebugMode) {
          debugPrint(
            'CONFIG CACHED: $productId | '
            'groups=${product.modifierGroups.length} | '
            'sizes=${product.sizes.length}',
          );
        }
      },
      onError: (Object error) {
        final currentGeneration =
            _configurationRequestGenerations[
                productId];

        if (currentGeneration ==
            generation) {
          _configurationRequests.remove(
            productId,
          );
        }

        if (kDebugMode) {
          debugPrint(
            'CONFIG REQUEST FAILED: '
            '$productId | $error',
          );
        }
      },
    );

    return request;
  }

  @override
  Future<void> prefetchProductConfigurations(
    Iterable<String> productIds,
  ) async {
    final ids = productIds
        .where(
          (id) =>
              !_productConfigurationCache
                  .containsKey(id),
        )
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'CONFIG PREFETCH START: '
        '${ids.length} products',
      );
    }

    // Prefetch is intentionally conservative.
    //
    // Product details requested directly by the user
    // should have priority over background work.
    //
    // fetchProductConfiguration() already prevents
    // duplicate requests, so if the user taps a product
    // while it is being prefetched, the same Future is reused.
    for (final productId in ids) {
      try {
        await fetchProductConfiguration(
          productId,
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'CONFIG PREFETCH FAILED: '
            '$productId | $error',
          );
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'CONFIG PREFETCH COMPLETE: '
        '${ids.length} products',
      );
    }
  }

  Future<Product>
      _fetchProductConfigurationFromSupabase(
    String productId,
  ) async {
    final totalStopwatch =
        Stopwatch()..start();

    if (kDebugMode) {
      debugPrint(
        'FETCH CONFIG START: $productId',
      );
    }

    try {
      // Measures Supabase request time including:
      // network + backend processing + response transfer.
      final networkStopwatch =
          Stopwatch()..start();

      final row = await _client
          .from('products')
          .select('''
            id,
            name,
            description,
            base_price,
            image_url,
            status,
            sort_order,
            categories(name),
            product_variants(
              id,
              label,
              price_delta,
              sort_order
            ),
            product_modifier_groups(
              sort_order,
              modifier_groups(
                id,
                name,
                min_select,
                max_select,
                required,
                modifiers(
                  id,
                  name,
                  price,
                  image_url,
                  sort_order
                )
              )
            )
          ''')
          .eq(
            'restaurant_id',
            TenantConfig.restaurantId,
          )
          .eq(
            'id',
            productId,
          )
          .maybeSingle();

      networkStopwatch.stop();

      if (row == null) {
        throw StateError(
          'Product not found: $productId',
        );
      }

      // Measures Dart-side JSON -> model conversion.
      final mappingStopwatch =
          Stopwatch()..start();

      final product =
          _mapConfiguredProduct(row);

      mappingStopwatch.stop();
      totalStopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'FETCH CONFIG COMPLETE: '
          '$productId | '
          'network=${networkStopwatch.elapsedMilliseconds}ms | '
          'mapping=${mappingStopwatch.elapsedMilliseconds}ms | '
          'total=${totalStopwatch.elapsedMilliseconds}ms | '
          'groups=${product.modifierGroups.length} | '
          'sizes=${product.sizes.length}',
        );
      }

      return product;
    } catch (error) {
      totalStopwatch.stop();

      if (kDebugMode) {
        debugPrint(
          'FETCH CONFIG ERROR: '
          '$productId | '
          '${totalStopwatch.elapsedMilliseconds}ms | '
          '$error',
        );
      }

      rethrow;
    }
  }

  Product _mapConfiguredProduct(
    Map<String, dynamic> row,
  ) {
    final variantsRaw = _asMapList(
      row['product_variants'],
    )..sort(
        (a, b) =>
            _sortOrder(a).compareTo(
          _sortOrder(b),
        ),
      );

    final sizes = variantsRaw
        .map(
          (variant) => ProductSize(
            id: variant['id'] as String,
            label: variant['label'] as String,
            priceDelta:
                (variant['price_delta'] as num?)
                        ?.toDouble() ??
                    0,
          ),
        )
        .toList();

    final productModifierGroupsRaw =
        _asMapList(
      row['product_modifier_groups'],
    )..sort(
        (a, b) =>
            _sortOrder(a).compareTo(
          _sortOrder(b),
        ),
      );

    final modifierGroups =
        <ModifierGroup>[];

    for (final productModifierGroup
        in productModifierGroupsRaw) {
      final groupRaw =
          productModifierGroup[
              'modifier_groups'];

      if (groupRaw == null ||
          groupRaw is! Map) {
        continue;
      }

      final group =
          Map<String, dynamic>.from(
        groupRaw,
      );

      final modifiersRaw =
          _asMapList(
        group['modifiers'],
      )..sort(
          (a, b) =>
              _sortOrder(a).compareTo(
            _sortOrder(b),
          ),
        );

      final modifiers =
          <Modifier>[];

      for (final modifier
          in modifiersRaw) {
        final modifierId =
            modifier['id'];

        final modifierName =
            modifier['name'];

        if (modifierId is! String ||
            modifierName is! String) {
          continue;
        }

        modifiers.add(
          Modifier(
            id: modifierId,
            name: modifierName,
            imageUrl:
                modifier['image_url']
                        as String? ??
                    '',
            price:
                (modifier['price'] as num?)
                        ?.toDouble() ??
                    0,
          ),
        );
      }

      final groupId =
          group['id'];

      final groupName =
          group['name'];

      if (groupId is! String ||
          groupName is! String) {
        continue;
      }

      modifierGroups.add(
        ModifierGroup(
          id: groupId,
          name: groupName,
          minSelect:
              (group['min_select'] as num?)
                      ?.toInt() ??
                  0,
          maxSelect:
              (group['max_select'] as num?)
                      ?.toInt() ??
                  1,
          required:
              group['required'] as bool? ??
                  false,
          modifiers: modifiers,
        ),
      );
    }

    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      description:
          row['description'] as String? ??
              '',
      basePrice:
          (row['base_price'] as num)
              .toDouble(),
      imageUrl:
          row['image_url'] as String? ??
              '',
      category:
          (row['categories']
                  as Map<String, dynamic>?)?['name']
              as String? ??
              'General',
      available:
          row['status'] == 'available',
      sizes: sizes,
      modifierGroups:
          modifierGroups,
    );
  }

  List<Map<String, dynamic>> _asMapList(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  int _sortOrder(
    Map<String, dynamic> row,
  ) {
    return (row['sort_order'] as num?)
            ?.toInt() ??
        0;
  }

  void _cacheProductConfiguration(
    Product product,
  ) {
    _removeProductFromReverseIndexes(
      product.id,
    );

    _productConfigurationCache[
        product.id] = product;

    for (final group
        in product.modifierGroups) {
      _productsByModifierGroup
          .putIfAbsent(
            group.id,
            () => <String>{},
          )
          .add(product.id);

      for (final modifier
          in group.modifiers) {
        _productsByModifier
            .putIfAbsent(
              modifier.id,
              () => <String>{},
            )
            .add(product.id);
      }
    }
  }

  void _removeProductFromReverseIndexes(
    String productId,
  ) {
    final emptyGroups =
        <String>[];

    for (final entry
        in _productsByModifierGroup
            .entries) {
      entry.value.remove(
        productId,
      );

      if (entry.value.isEmpty) {
        emptyGroups.add(
          entry.key,
        );
      }
    }

    for (final groupId
        in emptyGroups) {
      _productsByModifierGroup
          .remove(groupId);
    }

    final emptyModifiers =
        <String>[];

    for (final entry
        in _productsByModifier.entries) {
      entry.value.remove(
        productId,
      );

      if (entry.value.isEmpty) {
        emptyModifiers.add(
          entry.key,
        );
      }
    }

    for (final modifierId
        in emptyModifiers) {
      _productsByModifier.remove(
        modifierId,
      );
    }
  }

  @override
  void invalidateProductConfiguration(
    String productId,
  ) {
    _productConfigurationCache
        .remove(productId);

    _removeProductFromReverseIndexes(
      productId,
    );

    _configurationRequestGenerations[
        productId] =
        (_configurationRequestGenerations[
                    productId] ??
                0) +
            1;

    _configurationRequests.remove(
      productId,
    );

    if (kDebugMode) {
      debugPrint(
        'CONFIG INVALIDATED: $productId',
      );
    }
  }

  @override
  void invalidateProductConfigurationsByModifierGroup(
    String modifierGroupId,
  ) {
    final productIds =
        _productsByModifierGroup[
                    modifierGroupId]
                ?.toList() ??
            const <String>[];

    for (final productId
        in productIds) {
      invalidateProductConfiguration(
        productId,
      );
    }
  }

  @override
  void invalidateProductConfigurationsByModifier(
    String modifierId,
  ) {
    final productIds =
        _productsByModifier[
                    modifierId]
                ?.toList() ??
            const <String>[];

    for (final productId
        in productIds) {
      invalidateProductConfiguration(
        productId,
      );
    }
  }

  @override
  Future<Branding> fetchBranding() async {
    final row = await _client
        .from('restaurant_branding')
        .select('''
          primary_color,
          secondary_color,
          background_color,
          font_family,
          customer_primary_color,
          customer_secondary_color,
          customer_background_color,
          customer_logo_url,
          customer_cover_url
        ''')
        .eq(
          'restaurant_id',
          TenantConfig.restaurantId,
        )
        .maybeSingle();

    if (row == null) {
      return Branding.fallback;
    }

    return Branding.fromJson({
      'primaryColor':
          row['customer_primary_color'] ??
              row['primary_color'],
      'secondaryColor':
          row['customer_secondary_color'] ??
              row['secondary_color'],
      'backgroundColor':
          row['customer_background_color'] ??
              row['background_color'],
      'logo':
          row['customer_logo_url'],
      'cover':
          row['customer_cover_url'],
      'fontFamily':
          row['font_family'],
    });
  }

  @override
  Future<ExperienceSettings>
      fetchSettings() async {
    final row = await _client
        .from('restaurant_settings')
        .select('''
          currency,
          preparation_time_minutes,
          accepts_scheduled_orders,
          scheduled_order_max_days,
          customer_notes_enabled,
          operational_status,
          closure_message,
          accepts_delivery,
          accepts_pickup,
          min_order_amount,
          tax_rate,
          timezone,
          order_number_prefix
        ''')
        .eq(
          'restaurant_id',
          TenantConfig.restaurantId,
        )
        .maybeSingle();

    if (row == null) {
      return ExperienceSettings.fallback;
    }

    return ExperienceSettings.fromJson(
      row,
    );
  }

  @override
  Future<Promotion>
      fetchPromotion() async {
    final row = await _client
        .from('restaurant_promotions')
        .select(
          'title, subtitle, image_url',
        )
        .eq(
          'restaurant_id',
          TenantConfig.restaurantId,
        )
        .eq(
          'is_active',
          true,
        )
        .order('sort_order')
        .limit(1)
        .maybeSingle();

    if (row == null) {
      return const Promotion(
        title:
            'Fresh Batch Brew, Daily',
        subtitle:
            'Slow-brewed overnight for a smoother cup — try it iced.',
        imageUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1000&q=80&auto=format&fit=crop',
      );
    }

    return Promotion(
      title:
          row['title'] as String,
      subtitle:
          row['subtitle'] as String? ??
              '',
      imageUrl:
          row['image_url'] as String? ??
              '',
    );
  }

  @override
  Future<List<CafeLocation>>
      fetchLocations() async {
    final rows = await _client
        .from('restaurant_locations')
        .select('''
          id,
          name,
          address,
          map_url,
          latitude,
          longitude,
          is_primary,
          sort_order
        ''')
        .eq(
          'restaurant_id',
          TenantConfig.restaurantId,
        )
        .eq(
          'is_active',
          true,
        )
        .order('sort_order');

    return (rows as List<dynamic>)
        .map(
          (row) => CafeLocation(
            name:
                row['name'] as String,
            address:
                row['address']
                        as String? ??
                    '',
            mapUrl:
                row['map_url']
                        as String? ??
                    '',
            latitude:
                (row['latitude'] as num?)
                    ?.toDouble(),
            longitude:
                (row['longitude'] as num?)
                    ?.toDouble(),
          ),
        )
        .toList();
  }
}