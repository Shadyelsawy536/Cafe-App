import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/tenant_config.dart';
import '../../data/product_repository.dart';
import '../../domain/calculate_cart_total.dart';
import '../../models/branding.dart';
import '../../models/cafe_location.dart';
import '../../models/cart_item.dart';
import '../../models/customer_info.dart';
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

enum AddToCartStatus { idle, adding, added }

enum CheckoutStatus { idle, processing, success }

class OrderingController extends ChangeNotifier {
  OrderingController({ProductRepository? repository})
      : _repository = repository ?? MockProductRepository() {
    _listenToAuthChanges();

    if (_client.auth.currentSession != null) {
      unawaited(_startRealtime());
    }
  }

  final ProductRepository _repository;
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;
  StreamSubscription<AuthState>? _authSubscription;

  bool _realtimeStarted = false;
  bool _disposed = false;

  bool loading = true;
  ThemeMode themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  List<Product> products = [];

  Branding branding = Branding.fallback;
  ExperienceSettings settings = ExperienceSettings.fallback;
  Promotion? promotion;
  List<CafeLocation> locations = [];

  List<String> get categories =>
      products.map((p) => p.category).toSet().toList();

  // =========================================================
  // PRODUCT CONFIGURATION
  // =========================================================

  ProductSize? selectedSize;

  final Map<String, Set<Modifier>> selectedModifiers = {};

  int quantity = 1;

  AddToCartStatus addToCartStatus = AddToCartStatus.idle;

  // =========================================================
  // CART + CHECKOUT
  // =========================================================

  final List<CartItem> cart = [];

  CheckoutStatus checkoutStatus = CheckoutStatus.idle;

  String? checkoutError;

  CartTotals? lastOrderTotals;

  List<CartItem> lastOrderItems = [];

  // =========================================================
  // ORDER HISTORY
  // =========================================================

  final List<Order> orderHistory = [];

  CustomerInfo? lastCustomerInfo;

  int get cartCount =>
      cart.fold<int>(0, (sum, item) => sum + item.quantity);

  // =========================================================
  // AUTH
  // =========================================================

  void _listenToAuthChanges() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (_disposed) return;

      final session = data.session;

      debugPrint(
        'AUTH REALTIME: ${data.event} | session=${session != null}',
      );

      if (session != null) {
        unawaited(_startRealtime());
        unawaited(loadOrderHistory());
      } else {
        unawaited(_stopRealtime());

        orderHistory.clear();

        if (!_disposed) {
          notifyListeners();
        }
      }
    });
  }

  // =========================================================
  // REALTIME
  // =========================================================

  Future<void> _startRealtime() async {
    if (_realtimeStarted || _disposed) {
      debugPrint(
        'REALTIME: already started or controller disposed',
      );
      return;
    }

    _realtimeStarted = true;

    debugPrint('========================================');
    debugPrint('REALTIME: STARTING');
    debugPrint(
      'REALTIME: restaurant=${TenantConfig.restaurantId}',
    );
    debugPrint(
      'REALTIME: user=${_client.auth.currentUser?.id}',
    );
    debugPrint('========================================');

    final channelName =
        'cafe-orders-${TenantConfig.restaurantId}-${_client.auth.currentUser?.id ?? 'anonymous'}';

    final channel = _client.channel(channelName);

    _realtimeChannel = channel;

    // =======================================================
    // ORDERS
    // =======================================================

    // IMPORTANT:
    // Do NOT use a restaurant_id filter here.
    //
    // RLS already controls which orders the customer can read.
    // The event causes loadOrderHistory(), which performs the
    // normal RLS-protected query.
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        debugPrint('----------------------------------------');
        debugPrint('REALTIME EVENT: ORDERS');
        debugPrint('event=${payload.eventType}');
        debugPrint('new=${payload.newRecord}');
        debugPrint('old=${payload.oldRecord}');
        debugPrint('----------------------------------------');

        if (_disposed) return;

        unawaited(loadOrderHistory());
      },
    );

    // =======================================================
    // PRODUCTS
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (payload) {
        debugPrint('----------------------------------------');
        debugPrint('REALTIME EVENT: PRODUCTS');
        debugPrint('event=${payload.eventType}');
        debugPrint('new=${payload.newRecord}');
        debugPrint('old=${payload.oldRecord}');
        debugPrint('----------------------------------------');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // CATEGORIES
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'categories',
      callback: (payload) {
        debugPrint('REALTIME EVENT: CATEGORIES');
        debugPrint('event=${payload.eventType}');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // PRODUCT VARIANTS
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'product_variants',
      callback: (payload) {
        debugPrint('REALTIME EVENT: PRODUCT VARIANTS');
        debugPrint('event=${payload.eventType}');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // MODIFIER GROUPS
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'modifier_groups',
      callback: (payload) {
        debugPrint('REALTIME EVENT: MODIFIER GROUPS');
        debugPrint('event=${payload.eventType}');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // MODIFIERS
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'modifiers',
      callback: (payload) {
        debugPrint('REALTIME EVENT: MODIFIERS');
        debugPrint('event=${payload.eventType}');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // PRODUCT MODIFIER GROUPS
    // =======================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'product_modifier_groups',
      callback: (payload) {
        debugPrint('REALTIME EVENT: PRODUCT MODIFIER GROUPS');
        debugPrint('event=${payload.eventType}');

        if (_disposed) return;

        unawaited(_reloadProducts());
      },
    );

    // =======================================================
    // SUBSCRIBE
    // =======================================================

    channel.subscribe((status, error) {
      debugPrint('========================================');
      debugPrint('REALTIME SUBSCRIBE STATUS: $status');

      if (error != null) {
        debugPrint('REALTIME SUBSCRIBE ERROR: $error');
      }

      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('REALTIME: CONNECTED SUCCESSFULLY');
      }

      if (status == RealtimeSubscribeStatus.channelError) {
        debugPrint('REALTIME: CHANNEL ERROR');
      }

      if (status == RealtimeSubscribeStatus.timedOut) {
        debugPrint('REALTIME: TIMEOUT');
      }

      debugPrint('========================================');
    });
  }

  // =========================================================
  // STOP REALTIME
  // =========================================================

  Future<void> _stopRealtime() async {
    final channel = _realtimeChannel;

    _realtimeChannel = null;
    _realtimeStarted = false;

    if (channel == null) {
      return;
    }

    debugPrint('REALTIME: STOPPING');

    try {
      await _client.removeChannel(channel);
    } catch (e) {
      debugPrint('REALTIME: error while stopping: $e');
    }

    debugPrint('REALTIME: STOPPED');
  }

  // =========================================================
  // PRODUCTS REFRESH
  // =========================================================

  Future<void> _reloadProducts() async {
    if (_disposed) return;

    try {
      debugPrint('REALTIME: refreshing products...');

      final freshProducts =
          await _repository.fetchProducts();

      if (_disposed) return;

      products = freshProducts;

      notifyListeners();

      debugPrint(
        'REALTIME: products refreshed successfully',
      );
    } catch (e) {
      debugPrint(
        'REALTIME: products refresh failed: $e',
      );
    }
  }

  // =========================================================
  // INITIAL DATA
  // =========================================================

  Future<void> loadData() async {
    loading = true;

    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchProducts(),
        _repository.fetchBranding(),
        _repository.fetchSettings(),
        _repository.fetchPromotion(),
        _repository.fetchLocations(),
      ]);

      if (_disposed) return;

      products = results[0] as List<Product>;
      branding = results[1] as Branding;
      settings = results[2] as ExperienceSettings;
      promotion = results[3] as Promotion;
      locations = results[4] as List<CafeLocation>;

      if (_client.auth.currentSession != null) {
        await _startRealtime();
      }
    } catch (e) {
      debugPrint('loadData error: $e');
    }

    if (_disposed) return;

    loading = false;

    notifyListeners();
  }

  // =========================================================
  // PRODUCT CONFIGURATION
  // =========================================================

  void beginConfiguring(Product product) {
    selectedSize =
        product.sizes.isNotEmpty ? product.sizes.first : null;

    selectedModifiers.clear();

    quantity = 1;

    addToCartStatus = AddToCartStatus.idle;

    notifyListeners();
  }

  void selectSize(ProductSize size) {
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

  bool canAddToCart(Product product) {
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

  double currentUnitPrice(Product product) =>
      product.basePrice +
      (selectedSize?.priceDelta ?? 0) +
      selectedModifiers.values
          .expand((set) => set)
          .fold<double>(
            0,
            (sum, m) => sum + m.price,
          );

  double currentTotal(Product product) =>
      currentUnitPrice(product) * quantity;

  // =========================================================
  // CART
  // =========================================================

  Future<void> addToCart(Product product) async {
    addToCartStatus = AddToCartStatus.adding;

    notifyListeners();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

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

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    addToCartStatus = AddToCartStatus.idle;

    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    notifyListeners();
  }

  String _quickAddLineId(Product product) =>
      'quick_${product.id}';

  int quickAddQuantityFor(Product product) {
    final id = _quickAddLineId(product);

    final index =
        cart.indexWhere((c) => c.id == id);

    return index == -1 ? 0 : cart[index].quantity;
  }

  void incrementQuickAdd(Product product) {
    final id = _quickAddLineId(product);

    final index =
        cart.indexWhere((c) => c.id == id);

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
      cart[index] =
          cart[index].copyWith(
        quantity:
            cart[index].quantity + 1,
      );
    }

    notifyListeners();
  }

  void decrementQuickAdd(Product product) {
    final id = _quickAddLineId(product);

    final index =
        cart.indexWhere((c) => c.id == id);

    if (index == -1) return;

    final current = cart[index];

    if (current.quantity <= 1) {
      cart.removeAt(index);
    } else {
      cart[index] =
          current.copyWith(
        quantity:
            current.quantity - 1,
      );
    }

    notifyListeners();
  }

  CartTotals get cartTotals =>
      calculateCartTotals(cart);

  // =========================================================
  // CHECKOUT
  // =========================================================

  Future<void> checkout(
    CustomerInfo customerInfo,
  ) async {
    checkoutStatus =
        CheckoutStatus.processing;

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
                  'full_name':
                      customerInfo.name,
                  'phone':
                      customerInfo.phone,
                },
                onConflict:
                    'restaurant_id,user_id',
              )
              .select('id')
              .single();

      final customerId =
          customerRow['id'] as String;

      final items = cart
          .map(
            (item) => {
              'product_id':
                  item.product.id,
              'variant_id':
                  item.size?.id,
              'quantity':
                  item.quantity,
              'modifier_ids':
                  item.modifiers
                      .map((m) => m.id)
                      .toList(),
            },
          )
          .toList();

      final orderId =
          await _client.rpc(
        'place_order',
        params: {
          'p_restaurant_id':
              TenantConfig.restaurantId,
          'p_customer_id':
              customerId,
          'p_customer_name':
              customerInfo.name,
          'p_customer_phone':
              customerInfo.phone,
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
          'p_items': items,
        },
      ) as String;

      final order =
          await _fetchOrderById(orderId);

      orderHistory.insert(0, order);

      lastOrderTotals =
          order.totals;

      lastOrderItems =
          order.items;

      lastCustomerInfo =
          customerInfo;

      cart.clear();

      checkoutStatus =
          CheckoutStatus.success;
    } catch (e) {
      checkoutStatus =
          CheckoutStatus.idle;

      checkoutError =
          e is PostgrestException
              ? e.message
              : e.toString()
                  .replaceFirst(
                    'Exception: ',
                    '',
                  );
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  // =========================================================
  // ORDER HISTORY
  // =========================================================

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
      debugPrint(
        'ORDER HISTORY: loading for user=$userId',
      );

      final rows =
          await _client
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
          (rows as List<dynamic>)
              .map(
                (row) => _mapOrderRow(
                  row as Map<String, dynamic>,
                ),
              ),
        );

      notifyListeners();

      debugPrint(
        'ORDER HISTORY: refreshed (${orderHistory.length} orders)',
      );
    } catch (e) {
      debugPrint(
        'ORDER HISTORY ERROR: $e',
      );
    }
  }

  Future<Order> _fetchOrderById(
    String orderId,
  ) async {
    final row =
        await _client
            .from('orders')
            .select(_orderSelectShape)
            .eq('id', orderId)
            .single();

    return _mapOrderRow(row);
  }

  // =========================================================
  // ORDER SELECT
  // =========================================================

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

  // =========================================================
  // MAP ORDER
  // =========================================================

  Order _mapOrderRow(
    Map<String, dynamic> row,
  ) {
    final items =
        (row['order_items'] as List<dynamic>)
            .map((raw) {
      final modifiers =
          (raw['order_item_modifiers']
                  as List<dynamic>)
              .map(
                (m) => Modifier(
                  id: '',
                  name:
                      m['modifier_name']
                          as String,
                  imageUrl: '',
                  price:
                      (m['price'] as num)
                          .toDouble(),
                ),
              )
              .toList();

      final variantLabel =
          raw['variant_label']
              as String?;

      final snapshotProduct =
          Product(
        id:
            raw['product_id']
                    as String? ??
                '',
        name:
            raw['product_name']
                as String,
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
        quantity:
            raw['quantity'] as int,
      );
    }).toList();

    final statusHistory =
        (row['order_status_history']
                as List<dynamic>)
            .map(
              (h) => OrderStatusEvent(
                status:
                    _parseOrderStatus(
                  h['status'] as String,
                ),
                timestamp:
                    DateTime.parse(
                  h['created_at']
                      as String,
                ),
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.timestamp
                .compareTo(b.timestamp),
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
        name:
            row['customer_name']
                as String,
        phone:
            row['customer_phone']
                as String,
        deliveryType:
            row['delivery_type'] ==
                    'delivery'
                ? DeliveryType.delivery
                : DeliveryType.pickup,
        address:
            row['delivery_address']
                as String?,
        pickupBranch:
            row['pickup_branch']
                as String?,
        paymentMethod:
            row['payment_method'] ==
                    'visa'
                ? PaymentMethod.visa
                : PaymentMethod.cash,
      ),
      placedAt:
          DateTime.parse(
        row['created_at']
            as String,
      ),
      status:
          _parseOrderStatus(
        row['status'] as String,
      ),
      statusHistory:
          statusHistory,
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

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

  // =========================================================
  // CHECKOUT RESET
  // =========================================================

  void resetCheckout() {
    checkoutStatus =
        CheckoutStatus.idle;

    checkoutError = null;

    notifyListeners();
  }

  // =========================================================
  // PROFILE
  // =========================================================

  void updateSavedProfile(
    CustomerInfo info,
  ) {
    lastCustomerInfo = info;

    notifyListeners();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

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