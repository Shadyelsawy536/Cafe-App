import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/tenant_config.dart';
import '../../data/delivery_zone_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/calculate_cart_total.dart';
import '../../models/branding.dart';
import '../../models/cafe_location.dart';
import '../../models/cart_item.dart';
import '../../models/customer_info.dart';
import '../../models/delivery_zone.dart';
import '../../models/experience_settings.dart';
import '../../models/modifier.dart';
import '../../models/modifier_group.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/order_status_event.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_size.dart';
import '../../models/promotion.dart';

enum AddToCartStatus {
  idle,
  adding,
  added,
}

enum CheckoutStatus {
  idle,
  processing,
  success,
}

class OrderingController extends ChangeNotifier {
  OrderingController({
    ProductRepository? repository,
  }) : _repository = repository ?? MockProductRepository() {
    _listenToAuthChanges();

    if (_client.auth.currentSession != null) {
      unawaited(
        _startRealtime(),
      );
    }
  }

  /// Public wrapper for UI extensions/widgets that need
  /// to trigger a ChangeNotifier update.
  void refreshUi() {
    notifyListeners();
  }

  final ProductRepository _repository;

  final DeliveryZoneRepository _deliveryZoneRepository =
      DeliveryZoneRepository();

  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;

  StreamSubscription<AuthState>? _authSubscription;

  bool _realtimeStarted = false;
  bool _disposed = false;

  bool loading = true;

  ThemeMode themeMode = ThemeMode.system;

  List<Product> products = [];

  Branding branding = Branding.fallback;

  ExperienceSettings settings = ExperienceSettings.fallback;

  Promotion? promotion;

  List<CafeLocation> locations = [];

  /// Tracks the product currently being configured.
  ///
  /// The actual configuration cache lives inside
  /// ProductRepository and can contain many products.
  String? _configuredProductId;

  bool loadingProductConfiguration = false;

  String? productConfigurationError;

  Product? get configuredProduct {
    final id = _configuredProductId;

    if (id == null) {
      return null;
    }

    return _repository.getCachedProductConfiguration(id);
  }

  List<String> get categories => products
      .map((p) => p.category)
      .toSet()
      .toList();

  ProductSize? selectedSize;

  final Map<String, Set<Modifier>> selectedModifiers = {};

  int quantity = 1;

  AddToCartStatus addToCartStatus = AddToCartStatus.idle;

  final List<CartItem> cart = [];

  CheckoutStatus checkoutStatus = CheckoutStatus.idle;

  String? checkoutError;

  CartTotals? lastOrderTotals;

  List<CartItem> lastOrderItems = [];

  final List<Order> orderHistory = [];

  CustomerInfo? lastCustomerInfo;

  DeliveryZone? deliveryZone;
  bool resolvingDeliveryZone = false;
  String? deliveryLocationError;
  double? deliveryLatitude;
  double? deliveryLongitude;

  Future<void>? _deliveryZoneRequest;

  int get cartCount => cart.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

  void setThemeMode(
    ThemeMode mode,
  ) {
    themeMode = mode;
    notifyListeners();
  }

  void _listenToAuthChanges() {
    _authSubscription =
        _client.auth.onAuthStateChange.listen(
      (data) {
        if (_disposed) return;

        final session = data.session;

        debugPrint(
          'AUTH REALTIME: ${data.event} | '
          'session=${session != null}',
        );

        if (session != null) {
          unawaited(
            _startRealtime(),
          );

          unawaited(
            loadOrderHistory(),
          );
        } else {
          unawaited(
            _stopRealtime(),
          );

          orderHistory.clear();

          if (!_disposed) {
            notifyListeners();
          }
        }
      },
    );
  }

  Future<void> _startRealtime() async {
    if (_realtimeStarted || _disposed) {
      return;
    }

    _realtimeStarted = true;

    debugPrint(
      'REALTIME: STARTING '
      'restaurant=${TenantConfig.restaurantId}',
    );

    final channelName =
        'cafe-orders-'
        '${TenantConfig.restaurantId}-'
        '${_client.auth.currentUser?.id ?? 'anonymous'}';

    final channel = _client.channel(channelName);

    _realtimeChannel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        if (_disposed) return;

        debugPrint(
          'REALTIME EVENT: ORDERS '
          '${payload.eventType}',
        );

        unawaited(
          loadOrderHistory(),
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (payload) {
        if (_disposed) return;

        final productId = _recordId(payload);

        if (productId != null) {
          _repository.invalidateProductConfiguration(
            productId,
          );
        }

        debugPrint(
          'REALTIME EVENT: PRODUCTS '
          '${payload.eventType}',
        );

        unawaited(
          _reloadProducts(),
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'categories',
      callback: (payload) {
        if (_disposed) return;

        debugPrint(
          'REALTIME EVENT: CATEGORIES '
          '${payload.eventType}',
        );

        unawaited(
          _reloadProducts(),
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'product_variants',
      callback: (payload) {
        if (_disposed) return;

        final productId = _recordValue(
          payload,
          'product_id',
        );

        if (productId != null) {
          _repository.invalidateProductConfiguration(
            productId,
          );
        }

        debugPrint(
          'REALTIME EVENT: PRODUCT VARIANTS '
          '${payload.eventType}',
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'product_modifier_groups',
      callback: (payload) {
        if (_disposed) return;

        final productId = _recordValue(
          payload,
          'product_id',
        );

        if (productId != null) {
          _repository.invalidateProductConfiguration(
            productId,
          );
        }

        debugPrint(
          'REALTIME EVENT: PRODUCT MODIFIER GROUPS '
          '${payload.eventType}',
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'modifier_groups',
      callback: (payload) {
        if (_disposed) return;

        final groupId = _recordId(payload);

        if (groupId != null) {
          _repository
              .invalidateProductConfigurationsByModifierGroup(
            groupId,
          );
        }

        debugPrint(
          'REALTIME EVENT: MODIFIER GROUPS '
          '${payload.eventType}',
        );
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'modifiers',
      callback: (payload) {
        if (_disposed) return;

        final modifierId = _recordId(payload);

        if (modifierId != null) {
          _repository
              .invalidateProductConfigurationsByModifier(
            modifierId,
          );
        }

        final modifierGroupId = _recordValue(
          payload,
          'modifier_group_id',
        );

        if (modifierGroupId != null) {
          _repository
              .invalidateProductConfigurationsByModifierGroup(
            modifierGroupId,
          );
        }

        debugPrint(
          'REALTIME EVENT: MODIFIERS '
          '${payload.eventType}',
        );
      },
    );

    channel.subscribe(
      (status, error) {
        debugPrint(
          'REALTIME SUBSCRIBE STATUS: '
          '$status',
        );

        if (error != null) {
          debugPrint(
            'REALTIME SUBSCRIBE ERROR: '
            '$error',
          );
        }

        if (status ==
            RealtimeSubscribeStatus.subscribed) {
          debugPrint(
            'REALTIME: CONNECTED SUCCESSFULLY',
          );
        }
      },
    );
  }

  Map<String, dynamic> _preferredRecord(
    PostgresChangePayload payload,
  ) {
    if (payload.newRecord.isNotEmpty) {
      return payload.newRecord;
    }

    return payload.oldRecord;
  }

  String? _recordId(
    PostgresChangePayload payload,
  ) {
    return _preferredRecord(payload)['id'] as String?;
  }

  String? _recordValue(
    PostgresChangePayload payload,
    String key,
  ) {
    return _preferredRecord(payload)[key] as String?;
  }

  Future<void> _stopRealtime() async {
    final channel = _realtimeChannel;

    _realtimeChannel = null;
    _realtimeStarted = false;

    if (channel == null) {
      return;
    }

    try {
      await _client.removeChannel(channel);
    } catch (e) {
      debugPrint(
        'REALTIME: error while stopping: '
        '$e',
      );
    }
  }

  Future<void> _reloadProducts() async {
    if (_disposed) return;

    try {
      final freshProducts =
          await _repository.fetchProducts();

      if (_disposed) return;

      products = freshProducts;

      notifyListeners();

      /// Refresh product configurations in the background.
      ///
      /// Only product IDs are passed to the repository.
      unawaited(
        _repository
            .prefetchProductConfigurations(
          freshProducts.map(
            (product) => product.id,
          ),
        )
            .catchError(
          (error) {
            debugPrint(
              'PRODUCT CONFIG PREFETCH ERROR: '
              '$error',
            );
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'REALTIME: products refresh failed: '
        '$e',
      );
    }
  }

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchProducts(),
        _repository.fetchBranding(),
        _repository.fetchSettings(),
        _repository.fetchPromotion(),
      ]);

      if (_disposed) return;

      products = results[0] as List<Product>;

      branding = results[1] as Branding;

      settings = results[2] as ExperienceSettings;

      promotion = results[3] as Promotion;

      loading = false;

      notifyListeners();

      /// Product configurations are NOT part of the
      /// critical catalog startup path.
      ///
      /// The catalog renders first, then configurations
      /// are fetched in the background.
      unawaited(
        _repository
            .prefetchProductConfigurations(
          products.map(
            (product) => product.id,
          ),
        )
            .catchError(
          (error) {
            debugPrint(
              'PRODUCT CONFIG PREFETCH ERROR: '
              '$error',
            );
          },
        ),
      );

      /// Locations are not required to render
      /// the main catalog.
      unawaited(
        _repository
            .fetchLocations()
            .then(
          (freshLocations) {
            if (_disposed) return;

            locations = freshLocations;

            notifyListeners();
          },
        ).catchError(
          (e) {
            debugPrint(
              'Background locations load error: '
              '$e',
            );
          },
        ),
      );

      /// Realtime is also not part of the critical
      /// startup path.
      ///
      /// Do not await it here. This allows loadData()
      /// to finish immediately after the catalog is ready.
      if (_client.auth.currentSession != null) {
        unawaited(
          _startRealtime(),
        );
      }
    } catch (e) {
      debugPrint(
        'loadData error: $e',
      );

      if (_disposed) return;

      loading = false;

      notifyListeners();
    }
  }

  Future<Product> loadProductConfiguration(
    Product summaryProduct,
  ) async {
    final productId = summaryProduct.id;

    /// First check the repository cache directly.
    ///
    /// If background prefetch already completed,
    /// no network request is made and no loading spinner
    /// is shown.
    final cached =
        _repository.getCachedProductConfiguration(
      productId,
    );

    if (cached != null) {
      if (_disposed) {
        return cached;
      }

      _configuredProductId = cached.id;

      beginConfiguring(cached);

      loadingProductConfiguration = false;

      productConfigurationError = null;

      return cached;
    }

    loadingProductConfiguration = true;

    productConfigurationError = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final configured =
          await _repository.fetchProductConfiguration(
        productId,
      );

      if (_disposed) {
        return configured;
      }

      _configuredProductId = configured.id;

      beginConfiguring(configured);

      loadingProductConfiguration = false;

      productConfigurationError = null;

      notifyListeners();

      return configured;
    } catch (e) {
      if (!_disposed) {
        loadingProductConfiguration = false;

        productConfigurationError = e.toString();

        notifyListeners();
      }

      rethrow;
    }
  }

  void clearConfiguredProduct() {
    _configuredProductId = null;

    selectedSize = null;
    selectedModifiers.clear();
    quantity = 1;

    loadingProductConfiguration = false;

    productConfigurationError = null;

    notifyListeners();
  }

  void beginConfiguring(
    Product product,
  ) {
    _configuredProductId = product.id;

    selectedSize = product.sizes.isNotEmpty
        ? product.sizes.first
        : null;

    selectedModifiers.clear();

    quantity = 1;

    addToCartStatus = AddToCartStatus.idle;
  }

  void selectSize(
    ProductSize size,
  ) {
    selectedSize = size;
    notifyListeners();
  }

  Set<Modifier> selectedModifiersFor(
    ModifierGroup group,
  ) {
    return selectedModifiers[group.id] ?? const {};
  }

  void toggleModifier(
    ModifierGroup group,
    Modifier modifier,
  ) {
    final current =
        selectedModifiers.putIfAbsent(
      group.id,
      () => {},
    );

    if (current.contains(modifier)) {
      current.remove(modifier);
    } else if (group.isSingleChoice) {
      current
        ..clear()
        ..add(modifier);
    } else if (current.length < group.maxSelect) {
      current.add(modifier);
    } else {
      return;
    }

    notifyListeners();
  }

  bool canAddToCart(
    Product product,
  ) {
    for (final group in product.modifierGroups) {
      if (!group.required && group.minSelect == 0) {
        continue;
      }

      final chosen =
          selectedModifiersFor(group).length;

      if (chosen < group.minSelect ||
          (group.required && chosen == 0)) {
        return false;
      }
    }

    return true;
  }

  void incrementQuantity() {
    quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
      notifyListeners();
    }
  }

  double currentUnitPrice(
    Product product,
  ) =>
      product.basePrice +
      (selectedSize?.priceDelta ?? 0) +
      selectedModifiers.values
          .expand((set) => set)
          .fold<double>(
            0,
            (sum, modifier) => sum + modifier.price,
          );

  double currentTotal(
    Product product,
  ) =>
      currentUnitPrice(product) * quantity;

  Future<void> addToCart(
    Product product,
  ) async {
    if (!canAddToCart(product)) {
      return;
    }

    addToCartStatus = AddToCartStatus.adding;

    notifyListeners();

    cart.add(
      CartItem(
        id:
            '${product.id}_${DateTime.now().microsecondsSinceEpoch}',
        product: product,
        size: selectedSize,
        modifiers: selectedModifiers.values
            .expand((set) => set)
            .toList(),
        quantity: quantity,
      ),
    );

    addToCartStatus = AddToCartStatus.added;

    notifyListeners();

    unawaited(
      Future<void>.delayed(
        const Duration(
          milliseconds: 300,
        ),
        () {
          if (_disposed) return;

          addToCartStatus = AddToCartStatus.idle;

          notifyListeners();
        },
      ),
    );
  }

  void removeFromCart(
    CartItem item,
  ) {
    cart.remove(item);
    notifyListeners();
  }

  String _quickAddLineId(
    Product product,
  ) =>
      'quick_${product.id}';

  int quickAddQuantityFor(
    Product product,
  ) {
    final id = _quickAddLineId(product);

    final index = cart.indexWhere(
      (c) => c.id == id,
    );

    return index == -1 ? 0 : cart[index].quantity;
  }

  void incrementQuickAdd(
    Product product,
  ) {
    final id = _quickAddLineId(product);

    final index = cart.indexWhere(
      (c) => c.id == id,
    );

    if (index == -1) {
      cart.add(
        CartItem(
          id: id,
          product: product,
          size: product.sizes.isNotEmpty
              ? product.sizes.first
              : null,
          modifiers: const [],
          quantity: 1,
        ),
      );
    } else {
      cart[index] = cart[index].copyWith(
        quantity: cart[index].quantity + 1,
      );
    }

    notifyListeners();
  }

  void decrementQuickAdd(
    Product product,
  ) {
    final id = _quickAddLineId(product);

    final index = cart.indexWhere(
      (c) => c.id == id,
    );

    if (index == -1) return;

    final current = cart[index];

    if (current.quantity <= 1) {
      cart.removeAt(index);
    } else {
      cart[index] = current.copyWith(
        quantity: current.quantity - 1,
      );
    }

    notifyListeners();
  }

  CartTotals get cartTotals => calculateCartTotals(
        cart,
        taxRate: settings.taxRate,
      );

  Future<void> resolveDeliveryZone() {
    final existing = _deliveryZoneRequest;
    if (existing != null) {
      return existing;
    }

    final request = _resolveDeliveryZoneInternal();
    _deliveryZoneRequest = request;

    return request.whenComplete(() {
      if (identical(_deliveryZoneRequest, request)) {
        _deliveryZoneRequest = null;
      }
    });
  }

  Future<void> _resolveDeliveryZoneInternal() async {
    if (_disposed) return;

    resolvingDeliveryZone = true;
    deliveryLocationError = null;
    deliveryZone = null;
    deliveryLatitude = null;
    deliveryLongitude = null;

    notifyListeners();

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are turned off. Please enable location services to continue.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission is required for delivery orders.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Please enable it from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final zone =
          await _deliveryZoneRepository.findForCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (zone == null) {
        throw Exception(
          'Delivery is not available at your current location.',
        );
      }

      if (_disposed) return;

      deliveryZone = zone;
      deliveryLatitude = position.latitude;
      deliveryLongitude = position.longitude;
      resolvingDeliveryZone = false;
      deliveryLocationError = null;

      notifyListeners();
    } catch (e) {
      if (_disposed) return;

      resolvingDeliveryZone = false;
      deliveryZone = null;
      deliveryLatitude = null;
      deliveryLongitude = null;
      deliveryLocationError =
          e.toString().replaceFirst('Exception: ', '');

      notifyListeners();
    }
  }

  void clearDeliveryZone() {
    deliveryZone = null;
    deliveryLatitude = null;
    deliveryLongitude = null;
    deliveryLocationError = null;
    resolvingDeliveryZone = false;
    notifyListeners();
  }

  Future<void> checkout(
    CustomerInfo customerInfo,
  ) async {
    checkoutStatus = CheckoutStatus.processing;

    checkoutError = null;

    notifyListeners();

    try {
      final userId =
          _client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(
          'You must be signed in to place an order.',
        );
      }

      final customerRow =
          await _client
              .from('customers')
              .upsert(
        {
          'restaurant_id':
              TenantConfig.restaurantId,
          'user_id': userId,
          'full_name': customerInfo.name,
          'phone': customerInfo.phone,
        },
        onConflict: 'restaurant_id,user_id',
      )
              .select('id')
              .single();

      final customerId =
          customerRow['id'] as String;

      final items = cart
          .map(
            (item) => {
              'product_id': item.product.id,
              'variant_id': item.size?.id,
              'quantity': item.quantity,
              'modifier_ids': item.modifiers
                  .map(
                    (modifier) => modifier.id,
                  )
                  .toList(),
            },
          )
          .toList();

      final orderId =
          await _client.rpc(
        'place_order_with_location',
        params: {
          'p_restaurant_id':
              TenantConfig.restaurantId,
          'p_customer_id': customerId,
          'p_customer_name': customerInfo.name,
          'p_customer_phone': customerInfo.phone,
          'p_delivery_type':
              customerInfo.deliveryType ==
                      DeliveryType.delivery
                  ? 'delivery'
                  : 'pickup',
          'p_delivery_address':
              customerInfo.address,
          'p_pickup_branch':
              customerInfo.pickupBranch,
          'p_payment_method':
              customerInfo.paymentMethod ==
                      PaymentMethod.cash
                  ? 'cash'
                  : 'visa',
          'p_customer_notes':
              customerInfo.notes,
          'p_scheduled_for':
              customerInfo.scheduledFor
                  ?.toUtc()
                  .toIso8601String(),
          'p_latitude': customerInfo.deliveryLatitude,
          'p_longitude': customerInfo.deliveryLongitude,
          'p_items': items,
        },
      ) as String;

      final order = await _fetchOrderById(
        orderId,
      );

      orderHistory.insert(
        0,
        order,
      );

      lastOrderTotals = order.totals;

      lastOrderItems = order.items;

      lastCustomerInfo = customerInfo;

      deliveryZone = customerInfo.deliveryZoneId != null
          ? DeliveryZone(
              id: customerInfo.deliveryZoneId!,
              name: customerInfo.deliveryZoneName ?? '',
              deliveryFee: customerInfo.deliveryFee,
              minOrderAmount: 0,
            )
          : null;
      deliveryLatitude = customerInfo.deliveryLatitude;
      deliveryLongitude = customerInfo.deliveryLongitude;
      deliveryLocationError = null;

      cart.clear();

      checkoutStatus = CheckoutStatus.success;
    } catch (e) {
      checkoutStatus = CheckoutStatus.idle;

      checkoutError = e is PostgrestException
          ? e.message
          : e.toString().replaceFirst(
                'Exception: ',
                '',
              );
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadOrderHistory() async {
    final userId =
        _client.auth.currentUser?.id;

    if (userId == null) {
      orderHistory.clear();

      if (!_disposed) {
        notifyListeners();
      }

      return;
    }

    try {
      final rows = await _client
          .from('orders')
          .select(_orderSelectShape)
          .order(
            'created_at',
            ascending: false,
          );

      if (_disposed) return;

      orderHistory
        ..clear()
        ..addAll(
          (rows as List<dynamic>).map(
            (row) => _mapOrderRow(
              row as Map<String, dynamic>,
            ),
          ),
        );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'ORDER HISTORY ERROR: $e',
      );
    }
  }

  Future<Order> _fetchOrderById(
    String orderId,
  ) async {
    final row = await _client
        .from('orders')
        .select(_orderSelectShape)
        .eq(
          'id',
          orderId,
        )
        .single();

    return _mapOrderRow(row);
  }

  static const _orderSelectShape = '''
    id,
    customer_name,
    customer_phone,
    delivery_type,
    delivery_address,
    pickup_branch,
    payment_method,
    subtotal,
    tax,
    total,
    delivery_zone_id,
    delivery_zone_name,
    delivery_fee,
    delivery_latitude,
    delivery_longitude,
    status,
    created_at,
    order_items(
      id,
      product_id,
      product_name,
      variant_label,
      unit_price,
      quantity,
      line_total,
      order_item_modifiers(
        modifier_name,
        price
      )
    ),
    order_status_history(
      status,
      created_at
    )
  ''';

  Order _mapOrderRow(
    Map<String, dynamic> row,
  ) {
    final items =
        (row['order_items'] as List<dynamic>)
            .map(
      (raw) {
        final modifiers =
            (raw['order_item_modifiers']
                    as List<dynamic>)
                .map(
          (modifier) => Modifier(
            id: '',
            name:
                modifier['modifier_name']
                    as String,
            imageUrl: '',
            price:
                (modifier['price'] as num)
                    .toDouble(),
          ),
        )
                .toList();

        final variantLabel =
            raw['variant_label'] as String?;

        final snapshotProduct = Product(
          id: raw['product_id'] as String? ?? '',
          name: raw['product_name'] as String,
          description: '',
          basePrice:
              (raw['unit_price'] as num)
                  .toDouble(),
          imageUrl: '',
          category: '',
        );

        return CartItem(
          id: raw['id'] as String,
          product: snapshotProduct,
          size: variantLabel != null
              ? ProductSize(
                  id: '',
                  label: variantLabel,
                  priceDelta: 0,
                )
              : null,
          modifiers: modifiers,
          quantity: raw['quantity'] as int,
        );
      },
    ).toList();

    final statusHistory =
        (row['order_status_history']
                as List<dynamic>)
            .map(
      (history) => OrderStatusEvent(
        status: _parseOrderStatus(
          history['status'] as String,
        ),
        timestamp: DateTime.parse(
          history['created_at'] as String,
        ),
      ),
    ).toList()
          ..sort(
            (a, b) => a.timestamp.compareTo(
              b.timestamp,
            ),
          );

    return Order(
      id: row['id'] as String,
      items: items,
      totals: CartTotals(
        subtotal:
            (row['subtotal'] as num)
                .toDouble(),
        tax:
            (row['tax'] as num)
                .toDouble(),
        total:
            (row['total'] as num)
                .toDouble(),
      ),
      customer: CustomerInfo(
        name: row['customer_name'] as String,
        phone:
            row['customer_phone'] as String,
        deliveryType:
            row['delivery_type'] == 'delivery'
                ? DeliveryType.delivery
                : DeliveryType.pickup,
        deliveryZoneId:
            row['delivery_zone_id'] as String?,
        deliveryZoneName:
            row['delivery_zone_name'] as String?,
        deliveryFee:
            (row['delivery_fee'] as num?)?.toDouble() ?? 0,
        deliveryLatitude:
            (row['delivery_latitude'] as num?)?.toDouble(),
        deliveryLongitude:
            (row['delivery_longitude'] as num?)?.toDouble(),
        address:
            row['delivery_address'] as String?,
        pickupBranch:
            row['pickup_branch'] as String?,
        paymentMethod:
            row['payment_method'] == 'visa'
                ? PaymentMethod.visa
                : PaymentMethod.cash,
      ),
      placedAt: DateTime.parse(
        row['created_at'] as String,
      ),
      status: _parseOrderStatus(
        row['status'] as String,
      ),
      statusHistory: statusHistory,
    );
  }

  OrderStatus _parseOrderStatus(
    String value,
  ) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;

      case 'confirmed':
        return OrderStatus.confirmed;

      case 'preparing':
        return OrderStatus.preparing;

      case 'ready':
        return OrderStatus.ready;

      case 'out_for_delivery':
        return OrderStatus.outForDelivery;

      case 'delivered':
        return OrderStatus.delivered;

      case 'cancelled':
        return OrderStatus.cancelled;

      case 'rejected':
        return OrderStatus.rejected;

      default:
        return OrderStatus.pending;
    }
  }

  void resetCheckout() {
    checkoutStatus = CheckoutStatus.idle;

    checkoutError = null;

    notifyListeners();
  }

  void updateSavedProfile(
    CustomerInfo info,
  ) {
    lastCustomerInfo = info;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    _authSubscription?.cancel();

    final channel = _realtimeChannel;

    _realtimeChannel = null;
    _realtimeStarted = false;

    if (channel != null) {
      unawaited(
        _client.removeChannel(channel),
      );
    }

    super.dispose();
  }
}