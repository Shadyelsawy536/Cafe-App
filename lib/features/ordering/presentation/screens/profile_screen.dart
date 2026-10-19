import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../models/customer_info.dart';
import '../../models/payment_method.dart';
import '../controllers/ordering_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final info = context.read<OrderingController>().lastCustomerInfo;
    _nameController = TextEditingController(text: info?.name ?? '');
    _phoneController = TextEditingController(text: info?.phone ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
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
    final controller = context.watch<OrderingController>();
    final auth = context.watch<AuthController>();
    final orderCount = controller.orderHistory.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _AccountSection(auth: auth),
            const SizedBox(height: 28),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _nameController.text.isEmpty ? 'Guest' : _nameController.text,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('$orderCount orders placed', style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 28),
            Text('Saved details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _ThemeModeSelector(
              value: controller.themeMode,
              onChanged: controller.setThemeMode,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final controller = context.read<OrderingController>();
    controller.updateSavedProfile(
      CustomerInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryType: controller.lastCustomerInfo?.deliveryType ?? DeliveryType.delivery,
        address: _addressController.text.trim(),
        pickupBranch: controller.lastCustomerInfo?.pickupBranch,
        paymentMethod: controller.lastCustomerInfo?.paymentMethod ?? PaymentMethod.cash,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!auth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.account_circle_outlined, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You\'re browsing as a guest', style: theme.textTheme.titleLarge?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Sign in to save your details', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(Icons.person, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.currentUser!.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14)),
                Text(auth.currentUser!.email, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: auth.signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode_outlined),
      (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_outlined),
      (mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto_outlined),
    ];
    final theme = Theme.of(context);

    return Row(
      children: options
          .map(
            (option) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(option.mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: value == option.mode ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: value == option.mode
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: value == option.mode
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: value == option.mode
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
