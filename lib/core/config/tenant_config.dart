/// Cafe's restaurant row in Supabase. Hardcoded because this app is
/// single-tenant for now — when multi-tenant selection is built, this
/// becomes a runtime value instead of a constant, but nothing else in the
/// repository/controller layer needs to change to support that later.
class TenantConfig {
  static const restaurantId = 'e6323840-9644-471b-8964-203b76498a80';

  /// Public customer storefront used as the Paymob return target for the
  /// native app. The order id is added by the create-payment Edge Function.
  static const paymentRedirectBaseUrl =
      'https://shadyelsawy536.github.io/cafe-website/?restaurant=cafe';
}
