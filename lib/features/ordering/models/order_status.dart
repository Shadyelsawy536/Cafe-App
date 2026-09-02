import 'package:flutter/material.dart';

import 'customer_info.dart';

/// Matches the spec's order lifecycle (§19). Cancelled/Rejected are
/// terminal/error states and are shown separately from the progress
/// tracker rather than as a tracker step.
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
  rejected,
}

extension OrderStatusInfo on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.receipt_long_outlined;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.local_cafe_outlined;
      case OrderStatus.ready:
        return Icons.shopping_bag_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_outlined;
      case OrderStatus.delivered:
        return Icons.home_outlined;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}

/// Which statuses actually appear in the visual progress tracker, and in
/// what order — this differs by delivery type (a pickup order has no
/// "Out for Delivery" step; its useful end state is "Ready for Pickup").
List<OrderStatus> trackerStagesFor(DeliveryType deliveryType) {
  return deliveryType == DeliveryType.delivery
      ? const [
          OrderStatus.pending,
          OrderStatus.preparing,
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
        ]
      : const [
          OrderStatus.pending,
          OrderStatus.preparing,
          OrderStatus.ready,
        ];
}
