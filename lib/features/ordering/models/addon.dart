/// An optional add-on / topping a customer can attach to a product.
class Addon {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  const Addon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory Addon.fromJson(Map<String, dynamic> json) => Addon(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        price: (json['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
      };

  // Equality by id rather than identity: once addons come from a real
  // backend, every fetch returns new object instances. Selection state
  // (a Set<Addon>) must still work correctly across those instances.
  @override
  bool operator ==(Object other) => other is Addon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
