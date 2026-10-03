import '../domain/calculate_cart_total.dart';
import 'cart_item.dart';
import 'customer_info.dart';
import 'order_status.dart';
import 'order_status_event.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final CartTotals totals;
  final CustomerInfo customer;
  final DateTime placedAt;
  final OrderStatus status;
  final List<OrderStatusEvent> statusHistory;

  const Order({
    required this.id,
    required this.items,
    required this.totals,
    required this.customer,
    required this.placedAt,
    required this.status,
    required this.statusHistory,
  });
}
