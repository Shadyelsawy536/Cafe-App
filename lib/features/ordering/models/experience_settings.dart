enum BrowseLayout { grid, list }

/// App-wide settings controlled by the Restaurant Dashboard.
class ExperienceSettings {
  final BrowseLayout browseLayout;
  final String currency;

  const ExperienceSettings({required this.browseLayout, this.currency = 'EGP'});

  factory ExperienceSettings.fromJson(Map<String, dynamic> json) {
    final rawLayout = json['browseLayout'] as String? ?? 'grid';
    final rawCurrency = (json['currency'] as String? ?? 'EGP').trim().toUpperCase();
    return ExperienceSettings(
      browseLayout: rawLayout == 'list' ? BrowseLayout.list : BrowseLayout.grid,
      currency: rawCurrency.isEmpty ? 'EGP' : rawCurrency,
    );
  }

  static const fallback = ExperienceSettings(browseLayout: BrowseLayout.grid, currency: 'EGP');
}
