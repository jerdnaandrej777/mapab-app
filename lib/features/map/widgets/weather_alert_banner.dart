import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/weather.dart';
import '../providers/weather_provider.dart';

/// Provider für den Dismissed-State des Wetter-Alerts (v1.7.6)
/// Speichert ob das Banner in dieser Session bereits geschlossen wurde
final weatherAlertDismissedProvider = StateProvider<bool>((ref) => false);

/// Proaktives Wetter-Alert Banner (v1.7.6)
/// Erscheint bei schlechtem Wetter am Standort
class WeatherAlertBanner extends ConsumerWidget {
  const WeatherAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(locationWeatherNotifierProvider);
    final isDismissed = ref.watch(weatherAlertDismissedProvider);

    // Nicht anzeigen wenn:
    // - Kein Wetter geladen
    // - Kein schlechtes Wetter
    // - Bereits dismissed
    if (!weatherState.hasWeather ||
        !weatherState.showWarning ||
        isDismissed) {
      return const SizedBox.shrink();
    }

    final weather = weatherState.weather!;
    final condition = weather.condition;
    final isDanger = condition == WeatherCondition.danger;

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger ? Colors.red.shade200 : Colors.orange.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header mit Icon und Dismiss
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
              child: Row(
                children: [
                  Icon(
                    isDanger ? Icons.warning_amber_rounded : Icons.cloud,
                    color: isDanger ? Colors.red.shade700 : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDanger ? 'Unwetterwarnung' : 'Wetterhinweis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDanger ? Colors.red.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(weatherAlertDismissedProvider.notifier).state = true;
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: isDanger ? Colors.red.shade600 : Colors.orange.shade600,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Message
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAlertMessage(weather),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDanger ? Colors.red.shade900 : Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Empfehlung
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: isDanger ? Colors.red.shade600 : Colors.orange.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isDanger
                                    ? 'Bitte Outdoor-Aktivitäten vermeiden'
                                    : 'Indoor-Aktivitäten empfohlen',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDanger ? Colors.red.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Wetter-Icon
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      weather.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAlertMessage(Weather weather) {
    final condition = weather.condition;
    final code = weather.weatherCode;

    // Gewitter
    if (code >= 95) {
      if (weather.windSpeed > 60) {
        return 'Gewitter mit starken Winden (${weather.windSpeed.round()} km/h) in deiner Region.';
      }
      return 'Gewitter in deiner Region erwartet.';
    }

    // Schnee
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return 'Schneefall in deiner Region. Vorsicht auf glatten Straßen!';
    }

    // Starker Regen
    if (code >= 61 && code <= 67) {
      return 'Starker Regen (${weather.precipitation}mm) in deiner Region erwartet.';
    }

    // Leichter Regen
    if ((code >= 51 && code <= 57) || (code >= 80 && code <= 82)) {
      return 'Regenschauer in deiner Region möglich.';
    }

    // Nebel
    if (code >= 45 && code <= 48) {
      return 'Nebel in deiner Region. Eingeschränkte Sicht möglich.';
    }

    // Starker Wind
    if (weather.windSpeed > 60) {
      return 'Starke Winde (${weather.windSpeed.round()} km/h) in deiner Region.';
    }

    // Fallback
    if (condition == WeatherCondition.danger) {
      return 'Unwetter in deiner Region. Bitte Vorsicht!';
    }

    return 'Schlechtes Wetter in deiner Region erwartet.';
  }
}
