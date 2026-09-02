import 'package:flutter/material.dart';

import '../../models/order_status.dart';

/// Horizontal progress tracker — completed steps show a checkmark,
/// the current step is highlighted, future steps are dimmed, connected
/// by a line that fills in as progress advances.
class OrderStatusTracker extends StatelessWidget {
  const OrderStatusTracker({
    super.key,
    required this.stages,
    required this.currentStatus,
  });

  final List<OrderStatus> stages;
  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = stages.indexOf(currentStatus);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStepIndex = i ~/ 2;
          final isFilled = leftStepIndex < currentIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                height: 2,
                color: isFilled ? theme.colorScheme.primary : theme.dividerColor,
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final stage = stages[stepIndex];
        final isDone = stepIndex < currentIndex;
        final isCurrent = stepIndex == currentIndex;
        final isActive = isDone || isCurrent;

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? theme.colorScheme.primary : theme.cardColor,
                border: Border.all(
                  color: isActive ? theme.colorScheme.primary : theme.dividerColor,
                  width: 2,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : stage.icon,
                size: 16,
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                stage.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
