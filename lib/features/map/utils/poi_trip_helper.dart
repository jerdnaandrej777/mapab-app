import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';
import '../../trip/providers/trip_state_provider.dart';

/// Ergebnis eines POI-Hinzufuegen-Vorgangs
class POIAddResult {
  final bool success;
  final bool routeCreated;
  final bool gpsDisabled;
  final String? errorMessage;

  const POIAddResult({
    required this.success,
    this.routeCreated = false,
    this.gpsDisabled = false,
    this.errorMessage,
  });
}

/// Shared Utility fuer das Hinzufuegen von POIs zu Trips
/// Extrahiert aus poi_list_screen.dart - wiederverwendbar in beiden Panels
class POITripHelper {
  /// POI zur aktiven Route/Trip hinzufuegen
  ///
  /// Erkennt automatisch ob ein AI Trip aktiv ist und uebergibt
  /// dessen Route/Stops. Markiert AI Trip als confirmed bei Erfolg.
  static Future<POIAddResult> addPOIToTrip({
    required WidgetRef ref,
    required POI poi,
  }) async {
    final tripNotifier = ref.read(tripStateProvider.notifier);
    final tripData = ref.read(tripStateProvider);

    // AI Trip erkennen und Daten uebergeben
    AppRoute? aiRoute;
    List<POI>? aiStops;
    if (tripData.route == null) {
      final randomTripState = ref.read(randomTripNotifierProvider);
      if (randomTripState.generatedTrip != null &&
          (randomTripState.step == RandomTripStep.preview ||
              randomTripState.step == RandomTripStep.confirmed)) {
        aiRoute = randomTripState.generatedTrip!.trip.route;
        aiStops = randomTripState.generatedTrip!.selectedPOIs;
      }
    }

    final result = await tripNotifier.addStopWithAutoRoute(
      poi,
      existingAIRoute: aiRoute,
      existingAIStops: aiStops,
    );

    // AI Trip als bestaetigt markieren
    if (aiRoute != null && result.success) {
      ref.read(randomTripNotifierProvider.notifier).markAsConfirmed();
    }

    return POIAddResult(
      success: result.success,
      routeCreated: result.routeCreated,
      gpsDisabled: result.isGpsDisabled,
      errorMessage: result.message,
    );
  }

  /// GPS-Dialog anzeigen wenn GPS deaktiviert ist
  static Future<bool> showGpsDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('GPS deaktiviert'),
            content: const Text(
              'Die Ortungsdienste sind deaktiviert. '
              'Möchtest du die GPS-Einstellungen öffnen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nein'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Einstellungen öffnen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Vollstaendiger Add-Flow mit UI-Feedback (SnackBar, GPS-Dialog, Navigation)
  static Future<void> addPOIWithFeedback({
    required WidgetRef ref,
    required BuildContext context,
    required POI poi,
    bool navigateOnRouteCreated = false,
  }) async {
    final result = await addPOIToTrip(ref: ref, poi: poi);

    if (!context.mounted) return;

    if (result.success) {
      if (result.routeCreated && navigateOnRouteCreated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route zu "${poi.name}" erstellt'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${poi.name}" hinzugefügt'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (result.gpsDisabled) {
      final shouldOpen = await showGpsDialog(context);
      if (shouldOpen) {
        await Geolocator.openLocationSettings();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Fehler beim Hinzufügen'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
