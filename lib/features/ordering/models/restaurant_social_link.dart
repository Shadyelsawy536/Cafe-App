/// A social profile link managed by the Restaurant Dashboard.
class RestaurantSocialLink {
  final String platform;
  final String label;
  final String url;

  const RestaurantSocialLink({
    required this.platform,
    required this.label,
    required this.url,
  });

  factory RestaurantSocialLink.fromJson(Map<String, dynamic> json) {
    return RestaurantSocialLink(
      platform: (json['platform'] as String? ?? '').trim().toLowerCase(),
      label: (json['label'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
    );
  }
}
