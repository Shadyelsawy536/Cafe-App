import 'package:flutter/material.dart';

/// Per-tenant visual identity managed by the Restaurant Dashboard.
class Branding {
  final String logoUrl;
  final String coverUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final String? fontFamily;

  const Branding({
    required this.logoUrl,
    this.coverUrl = '',
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    this.fontFamily,
  });

  factory Branding.fromJson(Map<String, dynamic> json) => Branding(
        logoUrl: json['logo'] as String? ?? json['logoUrl'] as String? ?? '',
        coverUrl: json['cover'] as String? ?? json['coverUrl'] as String? ?? '',
        primaryColor:
            _colorFromHex(json['primaryColor'] as String? ?? '#8B4513'),
        secondaryColor:
            _colorFromHex(json['secondaryColor'] as String? ?? '#F5E6D3'),
        backgroundColor:
            _colorFromHex(json['backgroundColor'] as String? ?? '#FFF9F4'),
        fontFamily: json['fontFamily'] as String?,
      );

  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value =
        int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(value);
  }

  static const fallback = Branding(
    logoUrl: '',
    coverUrl: '',
    primaryColor: Color(0xFF8B4513),
    secondaryColor: Color(0xFFF5E6D3),
    backgroundColor: Color(0xFFFFF9F4),
  );
}
