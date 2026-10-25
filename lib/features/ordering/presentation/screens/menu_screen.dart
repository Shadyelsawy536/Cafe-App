import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/animations/route_transitions.dart';
import '../../../../core/config/tenant_config.dart';
import '../../models/cafe_location.dart';
import '../../models/experience_settings.dart';
import '../../models/product.dart';
import '../controllers/ordering_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/layout_toggle.dart';
import '../widgets/menu_product_card.dart';
import '../widgets/menu_product_list_tile.dart';
import 'product_details_screen.dart';

/// The full browsable catalog. Category chips stay pinned at the top;
/// tapping one scrolls to that section, and scrolling manually keeps the
/// chips in sync with whichever section is currently in view — the same
/// pattern most menu/food-delivery apps use.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _activeCategory;
  BrowseLayout _layout = BrowseLayout.grid;
  bool _layoutInitialized = false;
  bool _branchPromptHandled = false;
  bool _branchPickerVisible = false;

  static const double _chipRowHeight = 52;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveCategoryWithScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncActiveCategoryWithScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showBranchPicker(
    BuildContext context,
    OrderingController controller, {
    bool firstVisit = false,
  }) async {
    if (_branchPickerVisible || controller.locations.length < 2) return;
    _branchPickerVisible = true;
    String? nearestBranchId;
    final mapped = controller.locations
        .where((branch) => branch.latitude != null && branch.longitude != null)
        .toList();
    if (mapped.isNotEmpty) {
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied && firstVisit) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever &&
            await Geolocator.isLocationServiceEnabled()) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 6),
            ),
          );
          double distance(CafeLocation branch) => Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                branch.latitude!,
                branch.longitude!,
              );
          mapped.sort((a, b) => distance(a).compareTo(distance(b)));
          nearestBranchId = mapped.first.id;
        }
      } catch (_) {
        // Location is optional; the manual branch list always remains available.
      }
    }

    if (!context.mounted) {
      _branchPickerVisible = false;
      return;
    }
    final colors = Theme.of(context).colorScheme;
    String? selectedId = nearestBranchId ?? controller.selectedBranchId;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.storefront_rounded, color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstVisit ? 'Choose your branch' : 'Change branch',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Prices and availability depend on the branch you choose.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (nearestBranchId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.near_me_rounded, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nearest to you', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  controller.locations.firstWhere((branch) => branch.id == nearestBranchId).name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.auto_awesome_rounded, size: 19),
                        ],
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: controller.locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final branch = controller.locations[index];
                      final isSelected = selectedId == branch.id;
                      final isNearest = nearestBranchId == branch.id;
                      return Material(
                        color: isSelected ? colors.primaryContainer.withValues(alpha: .48) : colors.surface,
                        borderRadius: BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () => setSheetState(() => selectedId = branch.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.outlineVariant.withValues(alpha: .6),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(13)),
                                  child: Icon(Icons.location_on_outlined, color: isSelected ? colors.primary : colors.onSurfaceVariant),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(branch.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                                          if (isNearest) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.near_me_rounded, size: 14, color: colors.primary),
                                          ],
                                        ],
                                      ),
                                      if (branch.address.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(branch.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                                      ],
                                      if (branch.isPrimary && !isNearest) ...[
                                        const SizedBox(height: 4),
                                        Text('Main branch', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? colors.primary : colors.outlineVariant),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedId == null
                          ? null
                          : () async {
                              final branchId = selectedId!;
                              final hadCart = controller.cart.isNotEmpty && controller.selectedBranchId != branchId;
                              controller.setSelectedBranch(branchId);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('hubdine:selected-branch:${TenantConfig.restaurantId}', branchId);
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                              if (hadCart && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cart cleared because branch prices and availability can differ.')),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Continue with this branch', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    _branchPickerVisible = false;
  }

  void _promptForBranchIfNeeded(OrderingController controller) {
    if (_branchPromptHandled ||
        controller.locations.length < 2 ||
        controller.locations.any((branch) => branch.id.isEmpty)) {
      return;
    }
    _branchPromptHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final key = 'hubdine:selected-branch:${TenantConfig.restaurantId}';
      final saved = prefs.getString(key);
      if (saved != null && controller.locations.any((branch) => branch.id == saved)) {
        if (controller.selectedBranchId != saved) controller.setSelectedBranch(saved);
        return;
      }
      if (!mounted) return;
      await _showBranchPicker(context, controller, firstVisit: true);
    });
  }

  void _syncActiveCategoryWithScroll() {
    final viewportBox = _viewportKey.currentContext?.findRenderObject();
    if (viewportBox is! RenderBox || !viewportBox.attached) return;

    String? best;
    double? bestTop;

    for (final entry in _sectionKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      // Position relative to the scrollable viewport itself, not the whole
      // screen — this is what was wrong before: comparing global screen
      // coordinates against a threshold that only accounted for the chip
      // row's height, ignoring the app bar/status bar above it, so the
      // condition almost never matched correctly while scrolling.
      final top = renderObject.localToGlobal(Offset.zero, ancestor: viewportBox).dy;

      // A section counts as "active" once its top has reached (or passed)
      // the top of the visible menu area; among those, pick the lowest one.
      if (top <= 20) {
        if (bestTop == null || top > bestTop) {
          best = entry.key;
          bestTop = top;
        }
      }
    }

    if (best != null && best != _activeCategory) {
      setState(() => _activeCategory = best);
    }
  }

  void _scrollToCategory(String category) {
    final context = _sectionKeys[category]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0,
    );
    setState(() => _activeCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderingController>(
      builder: (context, controller, _) {
        if (controller.loading || controller.products.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Adopt the dashboard-controlled default exactly once, the first
        // time data is available — after that, the customer's own toggle
        // choice wins for the rest of this session.
        if (!_layoutInitialized) {
          _layout = controller.settings.browseLayout;
          _layoutInitialized = true;
        }

        _promptForBranchIfNeeded(controller);
        final categories = controller.categories;
        final activeCategory = _activeCategory ?? categories.first;
        final selectedBranch = controller.locations.isEmpty
            ? null
            : controller.locations.firstWhere(
                (location) => location.id == controller.selectedBranchId,
                orElse: () => controller.locations.first,
              );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
            actions: [
              if (controller.locations.length > 1 && controller.locations.every((location) => location.id.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: OutlinedButton.icon(
                    onPressed: () => _showBranchPicker(context, controller),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        selectedBranch?.name ?? 'Choose branch',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                ),
              LayoutToggle(
                layout: _layout,
                onChanged: (layout) => setState(() => _layout = layout),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: _chipRowHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories
                        .map(
                          (category) => CategoryChip(
                            label: category,
                            isSelected: category == activeCategory,
                            onTap: () => _scrollToCategory(category),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: _viewportKey,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.map((category) {
                        final items =
                            controller.products.where((p) => p.category == category).toList();
                        final key = _sectionKeys.putIfAbsent(category, () => GlobalKey());

                        return Column(
                          key: key,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 15),
                                ),
                                const Spacer(),
                                Text(
                                  '${items.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _layout == BrowseLayout.grid
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.60,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final product = items[index];
                                      return MenuProductCard(
                                        product: product,
                                        onTap: () => _openDetails(context, controller, product),
                                        quantity: controller.quickAddQuantityFor(product),
                                        onIncrement: () => controller.incrementQuickAdd(product),
                                        onDecrement: () => controller.decrementQuickAdd(product),
                                      );
                                    },
                                  )
                                : Column(
                                    children: items
                                        .map(
                                          (product) => MenuProductListTile(
                                            product: product,
                                            onTap: () =>
                                                _openDetails(context, controller, product),
                                            quantity: controller.quickAddQuantityFor(product),
                                            onIncrement: () =>
                                                controller.incrementQuickAdd(product),
                                            onDecrement: () =>
                                                controller.decrementQuickAdd(product),
                                          ),
                                        )
                                        .toList(),
                                  ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, OrderingController controller, Product product) {
    Navigator.of(context).push(buildDetailsRoute(ProductDetailsScreen(product: product)));
  }
}
