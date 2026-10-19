/// A physical branch managed by the Restaurant Dashboard.
class CafeLocation {
  final String name;
  final String address;
  final String mapUrl;
  final double? latitude;
  final double? longitude;

  const CafeLocation({
    required this.name,
    required this.address,
    this.mapUrl = '',
    this.latitude,
    this.longitude,
  });

  bool get hasMapLink => mapUrl.trim().isNotEmpty;
}
