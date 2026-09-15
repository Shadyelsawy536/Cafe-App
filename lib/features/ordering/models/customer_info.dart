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

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.deliveryType,
    this.address,
    this.pickupBranch,
    required this.paymentMethod,
    this.notes = '',
    this.scheduledFor,
  });
}
