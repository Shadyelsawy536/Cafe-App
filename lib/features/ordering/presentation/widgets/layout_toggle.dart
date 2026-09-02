import 'package:flutter/material.dart';

import '../../models/experience_settings.dart';

/// The grid/list switch for the Menu screen — a small segmented control,
/// same pattern as the reference design's two-icon toggle.
class LayoutToggle extends StatelessWidget {
  const LayoutToggle({super.key, required this.layout, required this.onChanged});

  final BrowseLayout layout;
  final ValueChanged<BrowseLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.grid_view_rounded,
            isActive: layout == BrowseLayout.grid,
            onTap: () => onChanged(BrowseLayout.grid),
          ),
          _ToggleIcon(
            icon: Icons.view_list_rounded,
            isActive: layout == BrowseLayout.list,
            onTap: () => onChanged(BrowseLayout.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({required this.icon, required this.isActive, required this.onTap});

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
