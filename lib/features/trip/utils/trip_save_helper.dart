import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/route.dart';
import '../../../data/providers/favorites_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';
import '../providers/trip_state_provider.dart';

/// Utility-Klasse fuer Trip-Speicher-Operationen
/// Kann von TripScreen, DayEditorOverlay und NavigationScreen genutzt werden
class TripSaveHelper {
  /// Speichert eine normale Route in die Favoriten
  static Future<bool> saveRoute(
    BuildContext context,
    WidgetRef ref,
    TripStateData tripState,
  ) async {
    final route = tripState.route;
    if (route == null) return false;

    // Dialog fuer Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripSaveRoute),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.tripRouteName,
            hintText: context.l10n.tripExampleDayTrip,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return false;

    // Trip erstellen
    final trip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: TripType.daytrip,
      route: route,
      stops: tripState.stops.map((poi) => TripStop.fromPOI(poi)).toList(),
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripRouteSaved(result)),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: context.l10n.tripShowInFavorites,
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
    return true;
  }

  /// Speichert einen AI Trip in die Favoriten
  static Future<bool> saveAITrip(
    BuildContext context,
    WidgetRef ref,
    RandomTripState randomTripState,
  ) async {
    final generatedTrip = randomTripState.generatedTrip;
    if (generatedTrip == null) return false;

    final trip = generatedTrip.trip;
    final route = trip.route;

    // Dialog fuer Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripSaveRoute),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.tripRouteName,
            hintText: randomTripState.mode == RandomTripMode.daytrip
                ? context.l10n.tripExampleAiDayTrip
                : context.l10n.tripExampleAiEuroTrip,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return false;

    // Trip mit korrektem Typ erstellen
    final savedTrip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: randomTripState.mode == RandomTripMode.daytrip
          ? TripType.daytrip
          : TripType.eurotrip,
      route: route,
      stops: trip.stops,
      days: trip.actualDays,
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(savedTrip);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripRouteSaved(result)),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: context.l10n.tripShowInFavorites,
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
    return true;
  }

  /// Speichert Route direkt mit Route und Stops (fuer NavigationScreen)
  static Future<bool> saveRouteDirectly(
    BuildContext context,
    WidgetRef ref, {
    required AppRoute route,
    required List<TripStop> stops,
    TripType type = TripType.daytrip,
    int? days,
  }) async {
    // Dialog fuer Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripSaveRoute),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.tripRouteName,
            hintText: context.l10n.tripExampleDayTrip,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return false;

    // Trip erstellen
    final trip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: type,
      route: route,
      stops: stops,
      days: days ?? 1,
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tripRouteSaved(result)),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: context.l10n.tripShowInFavorites,
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
    return true;
  }
}
