import 'package:flutter/material.dart';
import '../models/onboarding_page_data.dart';

/// Einzelne Onboarding-Seite mit Animation und Text
/// Zeigt die Animation oben und den Text mit Highlight unten
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation (obere Hälfte)
          Expanded(
            flex: 3,
            child: Center(
              child: data.animationBuilder(),
            ),
          ),

          // Text (untere Hälfte)
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Titel mit Highlight
                _buildHighlightedTitle(),

                const SizedBox(height: 16),

                // Untertitel
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Baut den Titel mit farbigem Highlight-Wort
  Widget _buildHighlightedTitle() {
    final title = data.title;
    final highlight = data.highlightWord;

    // Finde die Position des Highlight-Worts
    final highlightIndex = title.toLowerCase().indexOf(highlight.toLowerCase());

    if (highlightIndex == -1) {
      // Kein Highlight gefunden, normaler Text
      return Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.3,
        ),
      );
    }

    // Text in drei Teile aufteilen: vor, highlight, nach
    final beforeHighlight = title.substring(0, highlightIndex);
    final highlightText = title.substring(
      highlightIndex,
      highlightIndex + highlight.length,
    );
    final afterHighlight = title.substring(highlightIndex + highlight.length);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.3,
        ),
        children: [
          if (beforeHighlight.isNotEmpty)
            TextSpan(text: beforeHighlight),

          TextSpan(
            text: highlightText,
            style: TextStyle(
              color: data.highlightColor,
              shadows: [
                Shadow(
                  color: data.highlightColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),

          if (afterHighlight.isNotEmpty)
            TextSpan(text: afterHighlight),
        ],
      ),
    );
  }
}
