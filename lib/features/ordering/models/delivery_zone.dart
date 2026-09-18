class DeliveryZone {
  final String id;
  final String name;
  final double deliveryFee;
  final double minOrderAmount;

  const DeliveryZone({
    required this.id,
    required this.name,
    required this.deliveryFee,
    required this.minOrderAmount,
  });

  factory DeliveryZone.fromMap(
    Map<String, dynamic> map,
  ) {
    return DeliveryZone(
      id: map['id'] as String,
      name: map['name'] as String,
      deliveryFee:
          (map['delivery_fee'] as num).toDouble(),
      minOrderAmount:
          (map['min_order_amount'] as num).toDouble(),
    );
  }
}
