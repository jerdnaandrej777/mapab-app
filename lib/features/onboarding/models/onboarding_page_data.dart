import 'package:flutter/material.dart';

/// Daten für eine einzelne Onboarding-Seite
class OnboardingPageData {
  /// Titel der Seite (z.B. "Entdecke Sehenswürdigkeiten")
  final String title;

  /// Das Wort im Titel, das farbig hervorgehoben wird
  final String highlightWord;

  /// Untertitel/Beschreibung
  final String subtitle;

  /// Farbe für das Highlight-Wort
  final Color highlightColor;

  /// Builder-Funktion für die Animation
  final Widget Function() animationBuilder;

  const OnboardingPageData({
    required this.title,
    required this.highlightWord,
    required this.subtitle,
    required this.highlightColor,
    required this.animationBuilder,
  });
}
