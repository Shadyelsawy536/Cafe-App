/// Cafe's restaurant row in Supabase. Hardcoded because this app is
/// single-tenant for now — when multi-tenant selection is built, this
/// becomes a runtime value instead of a constant, but nothing else in the
/// repository/controller layer needs to change to support that later.
class TenantConfig {
  static const restaurantId = 'e6323840-9644-471b-8964-203b76498a80';
}
