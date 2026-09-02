enum BrowseLayout { grid, list }

/// App-wide experience toggles the Dashboard can eventually control (see
/// the "App Experience" section of the original spec). Only browseLayout
/// is wired today — more toggles (animation style, enabled sections) can
/// be added to this same model later without any screen changing, the
/// same way branding colors already work.
class ExperienceSettings {
  final BrowseLayout browseLayout;

  const ExperienceSettings({required this.browseLayout});

  factory ExperienceSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['browseLayout'] as String? ?? 'grid';
    return ExperienceSettings(
      browseLayout: raw == 'list' ? BrowseLayout.list : BrowseLayout.grid,
    );
  }

  static const fallback = ExperienceSettings(browseLayout: BrowseLayout.grid);
}
