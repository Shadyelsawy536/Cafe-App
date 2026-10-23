/// Per-restaurant values for this build.
///
/// They come from `config/restaurants/<slug>/restaurant.json`, passed to
/// Flutter with `--dart-define-from-file`. Use `dart run tool/hubdine_build.dart
/// <slug> <apk|appbundle|ios|run>` to build a restaurant.
///
/// The defaults below are the original Cafe values, so a plain `flutter run`
/// (no defines) behaves exactly as before.
class TenantConfig {
  static const restaurantId = String.fromEnvironment(
    'RESTAURANT_ID',
    defaultValue: 'e6323840-9644-471b-8964-203b76498a80',
  );

  /// Public customer storefront used as the Paymob return target for the
  /// native app. The order id is added by the create-payment Edge Function.
  static const paymentRedirectBaseUrl = String.fromEnvironment(
    'PAYMENT_REDIRECT_BASE_URL',
    defaultValue:
        'https://shadyelsawy536.github.io/cafe-website/?restaurant=cafe',
  );
}
