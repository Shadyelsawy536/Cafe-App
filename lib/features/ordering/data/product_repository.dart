import '../models/branding.dart';
import '../models/cafe_location.dart';
import '../models/experience_settings.dart';
import '../models/modifier.dart';
import '../models/modifier_group.dart';
import '../models/product.dart';
import '../models/product_size.dart';
import '../models/promotion.dart';

/// The contract the entire UI engine depends on. Every screen/widget talks
/// to this interface — never directly to Supabase, HTTP, or hardcoded data.
/// Swap [MockProductRepository] for a Supabase-backed implementation later
/// (e.g. `SupabaseProductRepository`) without touching any screen or widget.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Branding> fetchBranding();
  Future<ExperienceSettings> fetchSettings();
  Future<Promotion> fetchPromotion();
  Future<List<CafeLocation>> fetchLocations();
}

class MockProductRepository implements ProductRepository {
  @override
  Future<Branding> fetchBranding() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return Branding.fallback;
  }

  @override
  Future<ExperienceSettings> fetchSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ExperienceSettings.fallback;
  }

  @override
  Future<Promotion> fetchPromotion() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Promotion(
      title: 'Fresh Batch Brew, Daily',
      subtitle: 'Slow-brewed overnight for a smoother cup — try it iced.',
      imageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1000&q=80&auto=format&fit=crop',
    );
  }

  @override
  Future<List<CafeLocation>> fetchLocations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      CafeLocation(name: 'Central Avenue', address: 'First Sheikh Zayed, Albostan St.'),
      CafeLocation(name: 'Fuel Up Pyramids View', address: 'Fuel Up gas station, Ring Road'),
    ];
  }

  @override
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 600));

    const sizesStandard = [
      ProductSize(id: 's', label: 'S', priceDelta: 0),
      ProductSize(id: 'm', label: 'M', priceDelta: 0.5),
      ProductSize(id: 'l', label: 'L', priceDelta: 1.0),
    ];

    // Required, single-choice group — demonstrates minSelect/maxSelect/
    // required actually being enforced (Add to cart is blocked until one
    // milk is picked).
    const milkTypeGroup = ModifierGroup(
      id: 'milk_type',
      name: 'Milk Type',
      minSelect: 1,
      maxSelect: 1,
      required: true,
      modifiers: [
        Modifier(
          id: 'whole_milk',
          name: 'Whole Milk',
          imageUrl:
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&q=80&auto=format&fit=crop',
          price: 0,
        ),
        Modifier(
          id: 'oat_milk',
          name: 'Oat Milk',
          imageUrl:
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&q=80&auto=format&fit=crop',
          price: 0.5,
        ),
        Modifier(
          id: 'almond_milk',
          name: 'Almond Milk',
          imageUrl:
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&q=80&auto=format&fit=crop',
          price: 0.5,
        ),
      ],
    );

    // Optional, multi-choice group — pick up to 3.
    const extrasGroup = ModifierGroup(
      id: 'extras',
      name: 'Extras',
      minSelect: 0,
      maxSelect: 3,
      required: false,
      modifiers: [
        Modifier(
          id: 'extra_shot',
          name: 'Extra Shot',
          imageUrl:
              'https://images.unsplash.com/photo-1587734195503-904fca47e0d9?w=200&q=80&auto=format&fit=crop',
          price: 0.8,
        ),
        Modifier(
          id: 'vanilla',
          name: 'Vanilla',
          imageUrl:
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&q=80&auto=format&fit=crop',
          price: 0.5,
        ),
        Modifier(
          id: 'caramel',
          name: 'Caramel',
          imageUrl:
              'https://images.unsplash.com/photo-1481391319762-47dff72954d9?w=200&q=80&auto=format&fit=crop',
          price: 0.7,
        ),
      ],
    );

    return [
      const Product(
        id: 'batch_brew',
        name: 'Batch Brew',
        description:
            'Back home in our tasting room, we take these amazing coffees '
            'and mix them with beans from other regions.',
        basePrice: 3.0,
        imageUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=900&q=80&auto=format&fit=crop',
        category: 'Coffee',
        sizes: sizesStandard,
        modifierGroups: [milkTypeGroup, extrasGroup],
      ),
      const Product(
        id: 'caramel_macchiato',
        name: 'Caramel Macchiato',
        description:
            'Espresso with caramel drizzle and steamed milk, finished with foam.',
        basePrice: 3.5,
        imageUrl:
            'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=900&q=80&auto=format&fit=crop',
        category: 'Coffee',
        sizes: sizesStandard,
        modifierGroups: [milkTypeGroup, extrasGroup],
      ),
      const Product(
        id: 'matcha_latte',
        name: 'Matcha Latte',
        description: 'Creamy Japanese matcha whisked with steamed milk.',
        basePrice: 3.8,
        imageUrl:
            'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=900&q=80&auto=format&fit=crop',
        category: 'Matcha',
        sizes: sizesStandard,
        modifierGroups: [
          milkTypeGroup,
          ModifierGroup(
            id: 'sweetener',
            name: 'Sweetener',
            minSelect: 0,
            maxSelect: 1,
            required: false,
            modifiers: [
              Modifier(
                id: 'honey',
                name: 'Honey',
                imageUrl:
                    'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=200&q=80&auto=format&fit=crop',
                price: 0.4,
              ),
            ],
          ),
        ],
      ),
      const Product(
        id: 'jam_donut',
        name: 'Strawberry Jam Filled Donut',
        description:
            'Soft glazed donut filled with strawberry jam and topped with sprinkles.',
        basePrice: 2.5,
        imageUrl:
            'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=900&q=80&auto=format&fit=crop',
        category: 'Bakery',
        sizes: [],
        modifierGroups: [],
      ),
    ];
  }
}
