import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/animations/animation_constants.dart';
import '../../models/customer_info.dart';
import '../../models/payment_method.dart';
import '../controllers/ordering_controller.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppDurations.receiptCheck);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OrderingController>();
    final totals = controller.lastOrderTotals;
    final items = controller.lastOrderItems;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _closeReceipt(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: AppCurves.check),
                child: const Icon(Icons.check_circle, size: 72, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Order Successful!', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Thank you for your purchase',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            const SizedBox(height: 28),
            Text('Order Details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.product.name} x${item.quantity}'),
                    Text('€${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            if (totals != null) ...[
              _totalsRow('Subtotal', totals.subtotal),
              _totalsRow('Tax (10%)', totals.tax),
              const SizedBox(height: 8),
              _totalsRow('Total', totals.total, isBold: true),
            ],
            if (controller.lastCustomerInfo != null) ...[
              const Divider(height: 32),
              Text(
                controller.lastCustomerInfo!.deliveryType == DeliveryType.delivery
                    ? 'Delivery'
                    : 'Pickup',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                controller.lastCustomerInfo!.deliveryType == DeliveryType.delivery
                    ? (controller.lastCustomerInfo!.address ?? '')
                    : 'Pickup at ${controller.lastCustomerInfo!.pickupBranch ?? ''}',
              ),
              Text(controller.lastCustomerInfo!.phone,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              Text(
                'Paying with ${controller.lastCustomerInfo!.paymentMethod.label}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _closeReceipt(context, controller),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _closeReceipt(BuildContext context, OrderingController controller) {
    controller.resetCheckout();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _totalsRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      fontSize: isBold ? 18 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('€${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
