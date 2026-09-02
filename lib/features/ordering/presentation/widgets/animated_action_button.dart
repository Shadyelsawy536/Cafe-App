import 'package:flutter/material.dart';

enum ActionButtonStatus { idle, processing, success }

/// "Add to cart" and "Checkout" are the same interaction shape (idle ->
/// processing -> success), so they share one animated widget instead of
/// each screen reinventing its own button states.
class AnimatedActionButton extends StatelessWidget {
  const AnimatedActionButton({
    super.key,
    required this.status,
    required this.idleLabel,
    required this.onPressed,
  });

  final ActionButtonStatus status;
  final String idleLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = status == ActionButtonStatus.idle;
    final isProcessing = status == ActionButtonStatus.processing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // AnimatedContainer can't tween a width from double.infinity to a
        // finite value (BoxConstraints.lerp asserts on it) — so instead of
        // `double.infinity` for the idle/success width, use the actual
        // available width from LayoutBuilder, which is always finite.
        final fullWidth = constraints.maxWidth;

        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: isProcessing ? 56 : fullWidth,
            height: 56,
            child: ElevatedButton(
              onPressed: isEnabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: status == ActionButtonStatus.success
                    ? Colors.green.shade600
                    : Colors.black87,
                shape: isProcessing
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                padding: EdgeInsets.zero,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _buildChild(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChild() {
    switch (status) {
      case ActionButtonStatus.processing:
        return const SizedBox(
          key: ValueKey('processing'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
        );
      case ActionButtonStatus.success:
        return const Icon(Icons.check, key: ValueKey('success'), color: Colors.white);
      case ActionButtonStatus.idle:
        return Text(
          idleLabel,
          key: const ValueKey('idle'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        );
    }
  }
}
