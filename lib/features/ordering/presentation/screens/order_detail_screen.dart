import 'package:flutter/material.dart';

import '../../models/customer_info.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/payment_method.dart';
import '../widgets/order_status_history_list.dart';
import '../widgets/order_status_tracker.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = trackerStagesFor(order.customer.deliveryType);
    final isTerminalIssue =
        order.status == OrderStatus.cancelled || order.status == OrderStatus.rejected;

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id.substring(order.id.length - 6)}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (isTerminalIssue)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Text(order.status.label,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else
              OrderStatusTracker(stages: stages, currentStatus: order.status),
            const SizedBox(height: 32),
            Text('Order Details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.product.name} x${item.quantity}')),
                    Text('€${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleLarge),
                Text('€${order.totals.total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              order.customer.deliveryType == DeliveryType.delivery ? 'Delivery' : 'Pickup',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              order.customer.deliveryType == DeliveryType.delivery
                  ? (order.customer.address ?? '')
                  : 'Pickup at ${order.customer.pickupBranch ?? ''}',
            ),
            Text(order.customer.phone,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Text('Paying with ${order.customer.paymentMethod.label}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Text('Status History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            OrderStatusHistoryList(history: order.statusHistory),
          ],
        ),
      ),
    );
  }
}
