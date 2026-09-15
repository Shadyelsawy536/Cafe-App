import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_info.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/animated_action_button.dart';
import 'receipt_screen.dart';

/// IMPORTANT: this is a UI mock for the ordering flow, not a real payment
/// processor. Card fields are validated for format only and are never
/// stored, logged, or sent anywhere — they're discarded the moment this
/// screen closes. Before this app ever charges a real card, wire a
/// PCI-compliant provider (e.g. Stripe/Paymob) instead of collecting raw
/// card numbers directly like this.
class VisaPaymentScreen extends StatefulWidget {
  const VisaPaymentScreen({super.key, required this.customerInfo});

  final CustomerInfo customerInfo;

  @override
  State<VisaPaymentScreen> createState() => _VisaPaymentScreenState();
}

class _VisaPaymentScreenState extends State<VisaPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final totals = controller.cartTotals;

        return Scaffold(
          appBar: AppBar(title: const Text('Pay with Visa')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white70),
                        const SizedBox(height: 24),
                        Text(
                          _cardNumberController.text.isEmpty
                              ? '•••• •••• •••• ••••'
                              : _cardNumberController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.isEmpty
                              ? 'CARDHOLDER NAME'
                              : _nameController.text.toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Card number'),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(' ', '');
                      if (digits.length < 16) return 'Enter a valid card number';
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(labelText: 'MM/YY'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || value.length < 4) ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 3,
                          validator: (value) =>
                              (value == null || value.length < 3) ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Cardholder name'),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleLarge),
                      Text('€${totals.total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedActionButton(
                    status: _mapCheckout(controller.checkoutStatus),
                    idleLabel: 'Pay €${totals.total.toStringAsFixed(2)}',
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Card details are used for this order only and are not stored.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<OrderingController>();
    await controller.checkout(widget.customerInfo);

    if (!mounted) return;

    if (controller.checkoutStatus != CheckoutStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.checkoutError ?? 'Payment could not be completed. Please try again.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReceiptScreen()),
    );
  }

  ActionButtonStatus _mapCheckout(CheckoutStatus status) {
    switch (status) {
      case CheckoutStatus.processing:
        return ActionButtonStatus.processing;
      case CheckoutStatus.success:
        return ActionButtonStatus.success;
      case CheckoutStatus.idle:
        return ActionButtonStatus.idle;
    }
  }
}
