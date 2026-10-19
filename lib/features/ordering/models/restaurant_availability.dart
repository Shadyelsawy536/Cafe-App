/// Result of the backend's get_restaurant_availability() RPC -- the single
/// source of truth for whether the restaurant can take orders right now
/// (manual open/closed toggle AND the real weekly business-hours
/// schedule/breaks, evaluated in the restaurant's own timezone). Fetching
/// this instead of re-deriving it from raw settings client-side means the
/// app can never disagree with what place_order() will actually enforce.
class RestaurantAvailability {
  final bool isOpen;
  final String? message;

  const RestaurantAvailability({required this.isOpen, this.message});

  factory RestaurantAvailability.fromJson(Map<String, dynamic> json) {
    return RestaurantAvailability(
      isOpen: json['is_open'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  static const fallbackOpen = RestaurantAvailability(isOpen: true);
}
