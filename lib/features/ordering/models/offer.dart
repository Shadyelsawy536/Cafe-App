class Offer {
  const Offer({
    required this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.appliesTo,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String name;
  final String discountType;
  final double discountValue;
  final String appliesTo;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String,
        name: (json['name'] as String? ?? '').trim(),
        discountType: json['discount_type'] as String? ?? 'percentage',
        discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
        appliesTo: json['applies_to'] as String? ?? 'all',
        startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      );

  bool isCurrentAt(DateTime now) =>
      (startsAt == null || !startsAt!.isAfter(now)) &&
      (endsAt == null || endsAt!.isAfter(now));

  String get discountLabel {
    final value = discountValue == discountValue.roundToDouble()
        ? discountValue.toInt().toString()
        : discountValue.toString();
    return discountType == 'percentage' ? '$value% OFF' : '$value OFF';
  }

  String get scopeLabel {
    switch (appliesTo) {
      case 'product':
        return 'On selected products';
      case 'category':
        return 'On selected category';
      default:
        return 'On eligible items';
    }
  }
}
