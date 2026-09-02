/// A physical branch shown in Home's "Our Locations" section. Kept simple
/// on purpose — no live distance/geolocation, since that would need a paid
/// maps API. Just what the Dashboard would actually manage: name + address.
class CafeLocation {
  final String name;
  final String address;

  const CafeLocation({required this.name, required this.address});
}
