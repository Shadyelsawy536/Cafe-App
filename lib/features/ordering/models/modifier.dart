/// A single selectable option within a ModifierGroup (e.g. "Extra Shot",
/// "Oat Milk"). Maps to the spec's `modifiers` table.
class Modifier {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  const Modifier({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) => Modifier(
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

  // Equality by id rather than identity: once modifiers come from a real
  // backend, every fetch returns new object instances. Selection state
  // (a Set<Modifier>) must still work correctly across those instances.
  @override
  bool operator ==(Object other) => other is Modifier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
