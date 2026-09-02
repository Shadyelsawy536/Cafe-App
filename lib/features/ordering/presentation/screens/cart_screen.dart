import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/product_image.dart';
import 'checkout_details_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final theme = Theme.of(context);
        final totals = controller.cartTotals;
        final currency = controller.settings.currency;
        return Scaffold(
          appBar: AppBar(title: const Text('My Order')),
          body: controller.cart.isEmpty ? const Center(child: Text('Your cart is empty')) : ListView.separated(
            padding: const EdgeInsets.all(24), itemCount: controller.cart.length, separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = controller.cart[index];
              return Row(children: [
                ProductImage(imageUrl: item.product.imageUrl, width: 56, height: 56, borderRadius: 14), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                  if (item.size != null || item.modifiers.isNotEmpty) Text([if (item.size != null) item.size!.label, ...item.modifiers.map((m) => m.name)].join(' · '), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  Text('Qty ${item.quantity}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ])),
                Text(CurrencyFormatter.format(item.total, currency), style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => controller.removeFromCart(item)),
              ]);
            },
          ),
          bottomNavigationBar: controller.cart.isEmpty ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(CurrencyFormatter.format(totals.subtotal, currency))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tax (10%)'), Text(CurrencyFormatter.format(totals.tax, currency))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total', style: theme.textTheme.titleLarge), Text(CurrencyFormatter.format(totals.total, currency), style: theme.textTheme.titleLarge)]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goToCheckout(context), child: const Text('Checkout'))),
          ]))),
        );
      },
    );
  }

  Future<void> _goToCheckout(BuildContext context) async {
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!auth.isSignedIn) return;
    }
    if (context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutDetailsScreen()));
  }
}
