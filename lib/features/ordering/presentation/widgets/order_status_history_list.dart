import 'package:flutter/material.dart';

import '../../models/order_status.dart';
import '../../models/order_status_event.dart';

class OrderStatusHistoryList extends StatelessWidget {
  const OrderStatusHistoryList({super.key, required this.history});

  final List<OrderStatusEvent> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reversed = history.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reversed.map((event) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(event.status.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(event.status.label, style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                )),
              ),
              Text(_formatTime(event.timestamp), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
