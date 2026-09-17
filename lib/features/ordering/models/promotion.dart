/// The featured banner card on Home ("Curated for you" style). Dashboard
/// content, not hardcoded UI — swap the image/copy without touching
/// HomeScreen.
class Promotion {
  final String title;
  final String subtitle;
  final String imageUrl;

  const Promotion({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
