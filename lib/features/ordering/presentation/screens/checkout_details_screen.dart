import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
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
        final settings = controller.settings;
        final deliveryEnabled = settings.acceptsDelivery;
        final pickupEnabled = settings.acceptsPickup;

        if (!deliveryEnabled && _deliveryType == DeliveryType.delivery && pickupEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _deliveryType = DeliveryType.pickup);
          });
        }
        if (!pickupEnabled && _deliveryType == DeliveryType.pickup && deliveryEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _deliveryType = DeliveryType.delivery);
          });
        }

        final closed = settings.operationalStatus != RestaurantOperationalStatus.open;
        final minimumReached = totals.subtotal >= settings.minOrderAmount;

        return Scaffold(
          appBar: AppBar(title: const Text('Checkout Details')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (closed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        settings.closureMessage.isNotEmpty
                            ? settings.closureMessage
                            : 'We are not accepting orders right now.',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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
                  if (deliveryEnabled || pickupEnabled) ...[
                    const SizedBox(height: 28),
                    Text('Order Type', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (deliveryEnabled)
                          Expanded(
                            child: SelectableOptionTile(
                              label: 'Delivery',
                              icon: Icons.delivery_dining_outlined,
                              isSelected: _deliveryType == DeliveryType.delivery,
                              onTap: () => setState(() => _deliveryType = DeliveryType.delivery),
                            ),
                          ),
                        if (deliveryEnabled && pickupEnabled) const SizedBox(width: 12),
                        if (pickupEnabled)
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
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Enter a delivery address'
                            : null,
                      )
                    else
                      _BranchPicker(
                        locations: controller.locations,
                        selected: _pickupBranch,
                        onSelected: (name) => setState(() => _pickupBranch = name),
                      ),
                  ],
                  if (settings.customerNotesEnabled) ...[
                    const SizedBox(height: 20),
                    const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Order notes',
                        hintText: 'Anything we should know?',
                      ),
                    ),
                  ],
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
                  _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(totals.subtotal, settings.currency)),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Tax', value: CurrencyFormatter.format(totals.tax, settings.currency)),
                  const Divider(height: 28),
                  _SummaryRow(
                    label: 'Total',
                    value: CurrencyFormatter.format(totals.total, settings.currency),
                    emphasized: true,
                  ),
                  if (settings.minOrderAmount > 0 && !minimumReached) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Minimum order: ${CurrencyFormatter.format(settings.minOrderAmount, settings.currency)}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AnimatedActionButton(
                    status: _mapCheckout(controller.checkoutStatus),
                    idleLabel: _paymentMethod == PaymentMethod.visa ? 'Continue to Payment' : 'Place Order',
                    onPressed: closed || !minimumReached ? null : _submit,
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
    final controller = context.read<OrderingController>();
    final settings = controller.settings;
    final totals = controller.cartTotals;

    if (settings.operationalStatus != RestaurantOperationalStatus.open) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settings.closureMessage.isNotEmpty ? settings.closureMessage : 'Orders are currently closed.')),
      );
      return;
    }
    if (totals.subtotal < settings.minOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum order is ${CurrencyFormatter.format(settings.minOrderAmount, settings.currency)}')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_deliveryType == DeliveryType.pickup && _pickupBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a branch for pickup')));
      return;
    }

    final info = CustomerInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      deliveryType: _deliveryType,
      address: _deliveryType == DeliveryType.delivery ? _addressController.text.trim() : null,
      pickupBranch: _deliveryType == DeliveryType.pickup ? _pickupBranch : null,
      paymentMethod: _paymentMethod,
    );

    if (_paymentMethod == PaymentMethod.visa) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisaPaymentScreen(customerInfo: info)));
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

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceiptScreen()));
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _BranchPicker extends StatelessWidget {
  const _BranchPicker({required this.locations, required this.selected, required this.onSelected});
  final List<CafeLocation> locations;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (locations.isEmpty) {
      return Text('No branches available yet.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)));
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
                border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_circle : Icons.storefront_outlined, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.name, style: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                        Text(location.address, style: TextStyle(color: isSelected ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
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
