import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_info.dart';
import '../../models/order_status.dart';
import '../../models/payment_method.dart';
import '../controllers/ordering_controller.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Order history now comes from Supabase (scoped to the signed-in
    // customer via RLS) rather than an in-memory list, so it needs an
    // explicit fetch whenever this screen opens.
    context.read<OrderingController>().loadOrderHistory().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final orders = controller.orderHistory;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Order History')),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(order.placedAt),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 12),
                                ),
                                _StatusBadge(status: order.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...order.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.product.name} x${item.quantity}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 13, color: theme.colorScheme.onSurface),
                                    ),
                                    Text(
                                      '€${item.total.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 13, color: theme.colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                                Text(
                                  '€${order.totals.total.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.customer.paymentMethod.label} · ${order.customer.deliveryType == DeliveryType.delivery ? order.customer.address ?? '' : 'Pickup at ${order.customer.pickupBranch ?? ''}'}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · ${two(date.hour)}:${two(date.minute)}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isIssue = status == OrderStatus.cancelled || status == OrderStatus.rejected;
    final backgroundColor = isIssue ? Colors.redAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1);
    final textColor = isIssue ? Colors.redAccent.shade700 : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
