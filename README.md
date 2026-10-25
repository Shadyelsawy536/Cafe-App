# Cafe — Premium Ordering UI Engine

Phase 1 of the build: the animated UI engine wired to **mock data** that
matches the exact shape the real backend will return. No product content
is hardcoded into any screen or widget — every screen reads from
`OrderingController`, which reads from `ProductRepository`.

## HubDine white-label restaurant builds

For HubDine restaurant builds, keep each restaurant's configuration together
in its own folder. That folder is the source of truth; do not edit the copied
native Firebase files by hand.

```text
config/
└── restaurants/
    ├── slice-house/
    │   ├── restaurant.json
    │   ├── google-services.json
    │   ├── GoogleService-Info.plist
    │   └── icon.png
    └── vini-cafe/
        ├── restaurant.json
        ├── google-services.json
        ├── GoogleService-Info.plist
        └── icon.png
```

### Run on Android from Windows PowerShell

From the repository root, run:

```powershell
.\tool\run_restaurant.ps1 -Restaurant slice-house
```

This wrapper calls `tool/hubdine_build.dart`, which validates the selected
restaurant's `restaurant.json`, verifies that the Android package ID exists
in that restaurant's `google-services.json`, copies the Firebase file into
Android's expected location, prepares the iOS bundle/display-name config and
copies the iOS Firebase plist when present, generates launcher icons from
`icon.png`, then runs Flutter with that restaurant's Dart defines.

To pass different Flutter flags, provide them explicitly, for example:

```powershell
.\tool\run_restaurant.ps1 -Restaurant slice-house -FlutterArgs @('--debug')
```

For a release APK or app bundle, use the Dart build tool directly:

```powershell
dart run tool/hubdine_build.dart slice-house apk
dart run tool/hubdine_build.dart slice-house appbundle
```

Add a new restaurant by creating `config/restaurants/<slug>/` with the four
files above. The Firebase Android package in `google-services.json` must
match `ANDROID_APPLICATION_ID`; the iOS plist's `BUNDLE_ID` must match
`IOS_BUNDLE_ID`. The build tool stops with a clear error when the Android
Firebase package does not match. Android Gradle also reads `SLUG` and
`ANDROID_APPLICATION_ID` from the selected `restaurant.json`, validates the
matching Firebase package, and refreshes `android/app/google-services.json`
from that restaurant folder even when `flutter run` is invoked directly.
Prefer the wrapper for normal use because it also prepares the iOS plist,
bundle/display-name configuration, and launcher icon before running Flutter.

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
