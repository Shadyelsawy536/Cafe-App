/// A selectable size for a product (e.g. Small / Medium / Large).
/// [priceDelta] is added on top of the product's base price.
class ProductSize {
  final String id;
  final String label;
  final double priceDelta;

  const ProductSize({
    required this.id,
    required this.label,
    required this.priceDelta,
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) => ProductSize(
        id: json['id'] as String,
        label: json['label'] as String,
        priceDelta: (json['priceDelta'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'priceDelta': priceDelta,
      };
}
