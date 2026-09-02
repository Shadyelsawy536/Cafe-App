import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cafe_location.dart';
import '../../models/customer_info.dart';
import '../../models/payment_method.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/animated_action_button.dart';
import '../widgets/selectable_option_tile.dart';
import 'receipt_screen.dart';
import 'visa_payment_screen.dart';

class CheckoutDetailsScreen extends StatefulWidget {
  const CheckoutDetailsScreen({super.key});

  @override
  State<CheckoutDetailsScreen> createState() => _CheckoutDetailsScreenState();
}

class _CheckoutDetailsScreenState extends State<CheckoutDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DeliveryType _deliveryType = DeliveryType.delivery;
  String? _pickupBranch;

  @override
  void initState() {
    super.initState();
    // Prefill from whatever the customer used last time, if anything.
    final controller = context.read<OrderingController>();
    final previous = controller.lastCustomerInfo;
    _nameController = TextEditingController(text: previous?.name ?? '');
    _phoneController = TextEditingController(text: previous?.phone ?? '');
    _addressController = TextEditingController(text: previous?.address ?? '');
    _paymentMethod = previous?.paymentMethod ?? PaymentMethod.cash;
    _deliveryType = previous?.deliveryType ?? DeliveryType.delivery;
    _pickupBranch = previous?.pickupBranch ??
        (controller.locations.isNotEmpty ? controller.locations.first.name : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        final totals = controller.cartTotals;

        return Scaffold(
          appBar: AppBar(title: const Text('Checkout Details')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Contact', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  Text('Delivery', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableOptionTile(
                          label: 'Delivery',
                          icon: Icons.delivery_dining_outlined,
                          isSelected: _deliveryType == DeliveryType.delivery,
                          onTap: () => setState(() => _deliveryType = DeliveryType.delivery),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableOptionTile(
                          label: 'Pickup',
                          icon: Icons.storefront_outlined,
                          isSelected: _deliveryType == DeliveryType.pickup,
                          onTap: () => setState(() => _deliveryType = DeliveryType.pickup),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_deliveryType == DeliveryType.delivery)
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Delivery address'),
                      maxLines: 2,
                      validator: (value) {
                        if (_deliveryType != DeliveryType.delivery) return null;
                        return (value == null || value.trim().isEmpty)
                            ? 'Enter a delivery address'
                            : null;
                      },
                    )
                  else
                    _BranchPicker(
                      locations: controller.locations,
                      selected: _pickupBranch,
                      onSelected: (name) => setState(() => _pickupBranch = name),
                    ),
                  const SizedBox(height: 28),
                  Text('Payment Method', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableOptionTile(
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                          isSelected: _paymentMethod == PaymentMethod.cash,
                          onTap: () => setState(() => _paymentMethod = PaymentMethod.cash),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableOptionTile(
                          label: 'Visa',
                          icon: Icons.credit_card,
                          isSelected: _paymentMethod == PaymentMethod.visa,
                          onTap: () => setState(() => _paymentMethod = PaymentMethod.visa),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleLarge),
                      Text('€${totals.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedActionButton(
                    status: _mapCheckout(controller.checkoutStatus),
                    idleLabel: _paymentMethod == PaymentMethod.visa
                        ? 'Continue to Payment'
                        : 'Place Order',
                    onPressed: _submit,
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

    if (_deliveryType == DeliveryType.pickup && _pickupBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a branch for pickup')),
      );
      return;
    }

    final controller = context.read<OrderingController>();
    final info = CustomerInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      deliveryType: _deliveryType,
      address: _deliveryType == DeliveryType.delivery ? _addressController.text.trim() : null,
      pickupBranch: _deliveryType == DeliveryType.pickup ? _pickupBranch : null,
      paymentMethod: _paymentMethod,
    );

    if (_paymentMethod == PaymentMethod.visa) {
      // Visa needs card details before the order is actually placed —
      // that screen calls controller.checkout() itself once payment
      // "succeeds", then this screen unwinds the same way Cash does.
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VisaPaymentScreen(customerInfo: info)),
      );
      return;
    }

    await controller.checkout(info);

    if (!mounted) return;

    if (controller.checkoutStatus != CheckoutStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.checkoutError ?? 'Could not place your order. Please try again.')),
      );
      return;
    }

    // ReceiptScreen's Done/close button pops all the way back to the Menu,
    // which unwinds this screen too — nothing else to do once this returns.
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

class _BranchPicker extends StatelessWidget {
  const _BranchPicker({
    required this.locations,
    required this.selected,
    required this.onSelected,
  });

  final List<CafeLocation> locations;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (locations.isEmpty) {
      return Text(
        'No branches available yet.',
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      );
    }

    return Column(
      children: locations.map<Widget>((location) {
        final isSelected = location.name == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelected(location.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.storefront_outlined,
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          location.address,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
