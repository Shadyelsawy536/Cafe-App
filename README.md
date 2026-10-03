# Cafe — Premium Ordering UI Engine

Phase 1 of the build: the animated UI engine wired to **mock data** that
matches the exact shape the real backend will return. No product content
is hardcoded into any screen or widget — every screen reads from
`OrderingController`, which reads from `ProductRepository`.

## Setup (on your Windows machine)

You already have Flutter installed for EV Hub, so this is the same flow:

1. Create the Flutter shell if you haven't already:
   ```
   flutter create cafe_app
   ```
2. Copy the `lib/` folder and `pubspec.yaml` from this delivery into your
   `cafe_app` project (overwrite the generated `lib/main.dart`).
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run it:
   ```
   flutter run
   ```

## What's implemented

- **Hero showcase** — scale/opacity/translate intro animation, replays when
  the featured product changes.
- **Product carousel** — `PageView` with parallax (center product full size
  and opaque, side products smaller and faded).
- **Product details** — `Hero` continues the image from the carousel,
  animated size selector, animated add-on carousel, quantity stepper,
  price total via `AnimatedSwitcher`.
- **Add to cart** — button animates idle → spinner → checkmark before
  settling back to idle.
- **Cart ("My Order")** — line items, sticky bottom bar with
  subtotal/tax/total, animated checkout button.
- **Receipt** — spring-animated success checkmark (`Curves.elasticOut`),
  itemized breakdown.

All animation timing lives in `lib/core/animations/animation_constants.dart`
— tune the whole app's feel from one file.

## The seam for swapping in real data

`lib/features/ordering/data/product_repository.dart` defines:

```dart
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Branding> fetchBranding();
}
```

`MockProductRepository` implements it with an in-memory list. When you're
ready for Phase 3 (real backend), you'll add e.g.:

```dart
class FirestoreProductRepository implements ProductRepository {
  final tenantId = 'coffee_lab'; // hardcode for single-tenant phase

  @override
  Future<List<Product>> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tenants/$tenantId/products')
        .where('available', isEqualTo: true)
        .get();
    return snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
  }

  @override
  Future<Branding> fetchBranding() async {
    final doc = await FirebaseFirestore.instance
        .doc('tenants/$tenantId/branding/config')
        .get();
    return Branding.fromJson(doc.data()!);
  }
}
```

Then in `main.dart`, swap:
```dart
create: (_) => OrderingController()..loadData(),
```
to:
```dart
create: (_) => OrderingController(repository: FirestoreProductRepository())..loadData(),
```

No screen or widget changes — that's the whole point of the repository seam.

## Not yet wired (next phases)

- **Backend**: Firestore (`tenants/{tenantId}/products|addons|branding|orders`)
- **Images**: Cloudinary (free tier — 25GB storage/bandwidth vs. Firebase
  Storage's 1GB/day cap), swapped into `ProductImage`'s `imageUrl` source
- **Order persistence**: `checkout()` in `OrderingController` currently only
  clears local state — needs a Firestore write to `tenants/{tenantId}/orders`
- **React Dashboard**: CRUD for products/add-ons/branding, image upload to
  Cloudinary
- **Multi-tenant switching**: `tenantId` is hardcoded for now per your
  "single tenant now" call — promoting it to a runtime-selected value is a
  small change once you're ready

## Notes

- Mock images are hotlinked from Unsplash — fine for dev, replace with your
  own product photos (via Cloudinary) before shipping.
- State management is `provider` (`ChangeNotifier`) — simplest option that
  fits an app this size; can migrate to Riverpod/Bloc later if the app grows
  complex enough to need it.
- This hasn't been run through `flutter analyze`/`flutter run` in this
  environment (no Flutter SDK available here) — if you hit any errors on
  your machine, paste them back and I'll fix immediately.
# cafe_app
