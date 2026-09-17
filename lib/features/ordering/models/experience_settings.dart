enum BrowseLayout { grid, list }

enum RestaurantOperationalStatus { open, closed, temporarilyClosed }

/// Customer-facing configuration controlled by the Restaurant Dashboard.
class ExperienceSettings {
  final BrowseLayout browseLayout;
  final String currency;
  final int preparationTimeMinutes;
  final bool acceptsScheduledOrders;
  final int scheduledOrderMaxDays;
  final bool customerNotesEnabled;
  final RestaurantOperationalStatus operationalStatus;
  final String closureMessage;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final double minOrderAmount;
  final double taxRate;
  final String timezone;
  final String orderNumberPrefix;

  const ExperienceSettings({
    required this.browseLayout,
    this.currency = 'EGP',
    this.preparationTimeMinutes = 20,
    this.acceptsScheduledOrders = false,
    this.scheduledOrderMaxDays = 7,
    this.customerNotesEnabled = true,
    this.operationalStatus = RestaurantOperationalStatus.open,
    this.closureMessage = '',
    this.acceptsDelivery = true,
    this.acceptsPickup = true,
    this.minOrderAmount = 0,
    this.taxRate = 0,
    this.timezone = 'UTC',
    this.orderNumberPrefix = 'ORD',
  });

  factory ExperienceSettings.fromJson(Map<String, dynamic> json) {
    final rawLayout = json['browseLayout'] as String? ?? 'grid';
    final rawCurrency = (json['currency'] as String? ?? 'EGP').trim().toUpperCase();
    final rawStatus = (json['operational_status'] as String? ?? 'open').trim().toLowerCase();

    return ExperienceSettings(
      browseLayout: rawLayout == 'list' ? BrowseLayout.list : BrowseLayout.grid,
      currency: rawCurrency.isEmpty ? 'EGP' : rawCurrency,
      preparationTimeMinutes: (json['preparation_time_minutes'] as num?)?.toInt() ?? 20,
      acceptsScheduledOrders: json['accepts_scheduled_orders'] as bool? ?? false,
      scheduledOrderMaxDays: (json['scheduled_order_max_days'] as num?)?.toInt() ?? 7,
      customerNotesEnabled: json['customer_notes_enabled'] as bool? ?? true,
      operationalStatus: rawStatus == 'closed'
          ? RestaurantOperationalStatus.closed
          : rawStatus == 'temporarily_closed'
              ? RestaurantOperationalStatus.temporarilyClosed
              : RestaurantOperationalStatus.open,
      closureMessage: json['closure_message'] as String? ?? '',
      acceptsDelivery: json['accepts_delivery'] as bool? ?? true,
      acceptsPickup: json['accepts_pickup'] as bool? ?? true,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? 'UTC',
      orderNumberPrefix: json['order_number_prefix'] as String? ?? 'ORD',
    );
  }

  static const fallback = ExperienceSettings(
    browseLayout: BrowseLayout.grid,
    currency: 'EGP',
  );
}
