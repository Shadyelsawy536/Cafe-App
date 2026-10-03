import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/customer_info.dart';
import '../controllers/ordering_controller.dart';
import 'receipt_screen.dart';

class VisaPaymentScreen extends StatefulWidget {
  const VisaPaymentScreen({super.key, required this.customerInfo});

  final CustomerInfo customerInfo;

  @override
  State<VisaPaymentScreen> createState() => _VisaPaymentScreenState();
}

class _VisaPaymentScreenState extends State<VisaPaymentScreen> {
  bool _starting = true;
  String? _error;
  String? _checkoutUrl;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPayment());
  }

  Future<void> _startPayment() async {
    final controller = context.read<OrderingController>();
    await controller.checkout(widget.customerInfo);
    if (!mounted) return;

    if (controller.checkoutStatus != CheckoutStatus.success || controller.lastOrderId == null) {
      setState(() {
        _starting = false;
        _error = controller.checkoutError ?? 'Could not place your order. Please try again.';
      });
      return;
    }

    _orderId = controller.lastOrderId;

    try {
      final checkoutUrl = await controller.initiatePaymobPayment(_orderId!);
      if (!mounted) return;
      setState(() {
        _checkoutUrl = checkoutUrl;
        _starting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Order placed, but payment could not be started: ' + e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onPaymentReturned() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReceiptScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final returnedOrderId = uri?.queryParameters['order'];

            // Paymob returns to the storefront as ?restaurant=cafe&order=...
            // rather than /order/<id>. Catch that redirect inside the WebView
            // and return to the native receipt screen.
            if (_orderId != null && returnedOrderId == _orderId) {
              _onPaymentReturned();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_checkoutUrl!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with Visa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: WebViewWidget(controller: webController),
    );
  }
}
