/// A physical branch managed by the Restaurant Dashboard.
class CafeLocation {
  final String id;
  final String name;
  final String address;
  final String mapUrl;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;

  const CafeLocation({
    this.id = '',
    required this.name,
    required this.address,
    this.mapUrl = '',
    this.latitude,
    this.longitude,
    this.isPrimary = false,
  });

  bool get hasMapLink => mapUrl.trim().isNotEmpty;
}
