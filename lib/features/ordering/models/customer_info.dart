import 'payment_method.dart';

enum DeliveryType { delivery, pickup }

/// Collected on the checkout details screen and reused to prefill the
/// Profile screen and future orders.
///
/// Exactly one of [address] / [pickupBranch] is meaningful, depending on
/// [deliveryType] — this mirrors how a real order actually works (you
/// don't have both a delivery address and a pickup branch at once).
/// Once multi-tenant exists, which delivery methods a business even
/// offers becomes a Dashboard setting rather than always showing both.
class CustomerInfo {
  final String name;
  final String phone;
  final DeliveryType deliveryType;
  final String? address;
  final String? pickupBranch;
  final PaymentMethod paymentMethod;

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.deliveryType,
    this.address,
    this.pickupBranch,
    required this.paymentMethod,
  });
}
