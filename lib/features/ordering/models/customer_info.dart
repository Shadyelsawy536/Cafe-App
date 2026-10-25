import 'payment_method.dart';

enum DeliveryType { delivery, pickup }

/// Customer/order options collected during checkout.
class CustomerInfo {
  final String name;
  final String phone;
  final DeliveryType deliveryType;
  final String? address;
  final String? pickupBranch;
  final PaymentMethod paymentMethod;
  final String notes;
  final DateTime? scheduledFor;
  final String? deliveryZoneId;
  final String? deliveryZoneName;
  final double deliveryFee;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.deliveryType,
    this.address,
    this.pickupBranch,
    required this.paymentMethod,
    this.notes = '',
    this.scheduledFor,
    this.deliveryZoneId,
    this.deliveryZoneName,
    this.deliveryFee = 0,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });
}
