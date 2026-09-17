import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../models/modifier.dart';
import '../../models/modifier_group.dart';
import '../controllers/ordering_controller.dart';
import 'product_image.dart';

class ModifierGroupSection extends StatelessWidget {
  const ModifierGroupSection({super.key, required this.group, required this.selected, required this.onToggle});
  final ModifierGroup group;
  final Set<Modifier> selected;
  final ValueChanged<Modifier> onToggle;

  @override
  Widget build(BuildContext context) {
    if (group.modifiers.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final currency = context.watch<OrderingController>().settings.currency;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(group.name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(width: 8),
        Text(group.required ? 'Required' : group.isSingleChoice ? 'Choose 1' : 'Choose up to ${group.maxSelect}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: group.required ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      ]),
      const SizedBox(height: 10),
      SizedBox(height: 128, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: group.modifiers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final modifier = group.modifiers[index];
          final isSelected = selected.contains(modifier);
          return GestureDetector(
            onTap: () => onToggle(modifier),
            child: AnimatedScale(scale: isSelected ? 1.0 : 0.94, duration: const Duration(milliseconds: 220), curve: Curves.easeOutBack,
              child: AnimatedContainer(duration: const Duration(milliseconds: 220), width: 96, padding: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: isSelected ? theme.colorScheme.primary : theme.cardColor, border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ProductImage(imageUrl: modifier.imageUrl, width: 70, height: 55, borderRadius: 12),
                  const SizedBox(height: 6),
                  Text(modifier.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                  Text(modifier.price == 0 ? 'Free' : '+${CurrencyFormatter.format(modifier.price, currency)}', style: TextStyle(fontSize: 10, color: isSelected ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ]),
              ),
            ),
          );
        },
      )),
    ]);
  }
}
