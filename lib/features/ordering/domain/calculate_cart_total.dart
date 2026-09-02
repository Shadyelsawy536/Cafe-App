import '../models/cart_item.dart';

class CartTotals {
  final double subtotal;
  final double tax;
  final double total;

  const CartTotals({
    required this.subtotal,
    required this.tax,
    required this.total,
  });
}

/// Pure function, no Flutter/backend dependency — easy to unit test on its own.
CartTotals calculateCartTotals(List<CartItem> items, {double taxRate = 0.10}) {
  final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
  final tax = subtotal * taxRate;
  return CartTotals(subtotal: subtotal, tax: tax, total: subtotal + tax);
}
