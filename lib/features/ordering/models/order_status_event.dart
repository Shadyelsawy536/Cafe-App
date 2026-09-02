import 'order_status.dart';

/// One entry in an order's status history — maps to the spec's
/// `order_status_history` table (order_id, old_status, new_status,
/// changed_by, created_at). `changedBy` is omitted for now since there's
/// no auth/staff identity yet to attribute it to.
class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;

  const OrderStatusEvent({required this.status, required this.timestamp});
}
