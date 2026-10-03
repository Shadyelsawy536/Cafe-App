import 'package:flutter/material.dart';

/// Shows a simple "+ Add" button when quantity is 0, and morphs into a
/// "− N +" stepper once something's in the cart. Used by both the grid
/// card (full-width bar) and the list tile (compact floating pill) —
/// [compact] controls which visual footprint to use; the interaction
/// logic is identical either way.
///
/// Filled elements use the brand's primary color rather than a hardcoded
/// black — partly for brand consistency, partly because a near-black fill
/// has almost no visual separation against a dark-mode card background.
class QuickQuantityControl extends StatelessWidget {
  const QuickQuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: quantity <= 0
            ? _AddButton(key: const ValueKey('add'), onTap: onIncrement, compact: compact)
            : _Stepper(
                key: const ValueKey('stepper'),
                quantity: quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                compact: compact,
              ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 18),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add', style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          foregroundColor: theme.colorScheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.compact,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepButton(Icons.remove, onDecrement, theme.colorScheme.onPrimary),
            SizedBox(
              width: 18,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            _stepButton(Icons.add, onIncrement, theme.colorScheme.onPrimary),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stepButton(Icons.remove, onDecrement, theme.colorScheme.onPrimary),
          Text(
            '$quantity',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          _stepButton(Icons.add, onIncrement, theme.colorScheme.onPrimary),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
