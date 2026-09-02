import 'modifier_group.dart';
import 'product_size.dart';

/// Everything the Dashboard/backend controls about a sellable item.
/// The UI engine never hardcodes any of this — it only decides how
/// to *present* whatever product data it's handed.
class Product {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final String category;
  final bool available;
  final List<ProductSize> sizes;
  final List<ModifierGroup> modifierGroups;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    required this.category,
    this.available = true,
    this.sizes = const [],
    this.modifierGroups = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        basePrice: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String,
        category: json['category'] as String? ?? 'General',
        available: json['available'] as bool? ?? true,
        sizes: (json['sizes'] as List<dynamic>? ?? [])
            .map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
            .toList(),
        modifierGroups: (json['modifierGroups'] as List<dynamic>? ?? [])
            .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': basePrice,
        'imageUrl': imageUrl,
        'category': category,
        'available': available,
        'sizes': sizes.map((s) => s.toJson()).toList(),
        'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
      };
}
