import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  WebViewController? _webController;

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
      final webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              final returnedOrderId = uri?.queryParameters['order'];

              // Paymob's redirect is only a signal to check the server-side
              // payment state. Never rebuild/reload the Paymob WebView.
              if (_orderId != null && returnedOrderId == _orderId) {
                unawaited(_onPaymentReturned());
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(checkoutUrl));

      if (!mounted) return;
      setState(() {
        _checkoutUrl = checkoutUrl;
        _webController = webController;
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

  Future<void> _onPaymentReturned() async {
    if (_orderId == null || !mounted) return;

    // The Paymob redirect only tells us that Paymob sent the browser back.
    // The payment-webhook is the authoritative source of payment success.
    setState(() {
      _starting = true;
      _error = null;
    });

    final deadline = DateTime.now().add(
      const Duration(seconds: 30),
    );

    var paid = false;

    while (mounted && DateTime.now().isBefore(deadline)) {
      try {
        final row = await Supabase.instance.client
            .from('orders')
            .select('payment_verified')
            .eq('id', _orderId!)
            .maybeSingle();

        if (row?['payment_verified'] == true) {
          paid = true;
          break;
        }
      } catch (e) {
        debugPrint('PAYMENT CONFIRMATION CHECK ERROR: $e');
      }

      await Future<void>.delayed(
        const Duration(seconds: 1),
      );
    }

    if (!mounted) return;

    if (!paid) {
      setState(() {
        _starting = false;
        _error =
            'Payment was not confirmed yet. Please check your payment status and try again.';
      });
      return;
    }

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

    final webController = _webController;
    if (webController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
