import 'modifier.dart';
import 'product.dart';
import 'product_size.dart';

/// One configured line in the cart: a product plus the size/modifiers/
/// quantity the customer chose for it.
class CartItem {
  final String id;
  final Product product;
  final ProductSize? size;
  final List<Modifier> modifiers;
  final int quantity;

  CartItem({
    required this.id,
    required this.product,
    this.size,
    this.modifiers = const [],
    this.quantity = 1,
  });

  double get unitPrice =>
      product.basePrice +
      (size?.priceDelta ?? 0) +
      modifiers.fold<double>(0, (sum, m) => sum + m.price);

  double get total => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        product: product,
        size: size,
        modifiers: modifiers,
        quantity: quantity ?? this.quantity,
      );
}
