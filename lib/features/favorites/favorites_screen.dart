import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/models/poi.dart';
import '../../data/models/trip.dart';
import '../map/providers/map_controller_provider.dart';
import '../map/providers/route_planner_provider.dart';
import '../poi/providers/poi_state_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../trip/providers/trip_state_provider.dart';

/// Favoriten-Screen für gespeicherte Routen und POIs
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _enrichedPOIIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Enrichment für Favoriten-POIs nach erstem Frame starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enrichFavoritePOIs();
    });
  }

  /// Enriched alle Favoriten-POIs die noch kein Bild haben
  Future<void> _enrichFavoritePOIs() async {
    final favoritesAsync = ref.read(favoritesNotifierProvider);
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

    favoritesAsync.whenData((favorites) {
      for (final poi in favorites.favoritePOIs) {
        // Nur enrichen wenn noch kein Bild und nicht bereits enriched
        if (poi.imageUrl == null && !_enrichedPOIIds.contains(poi.id)) {
          _enrichedPOIIds.add(poi.id);
          debugPrint('[Favorites] Enriching POI: ${poi.name}');
          poiNotifier.enrichPOI(poi.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriten'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Routen'),
            Tab(icon: Icon(Icons.place), text: 'POIs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Alle löschen',
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (!favorites.hasFavorites) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRoutesList(favorites.savedRoutes),
              _buildPOIsList(favorites.favoritePOIs),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Favoriten',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speichere Routen und POIs für schnellen Zugriff',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.explore),
            label: const Text('Entdecken'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList(List<Trip> routes) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text('Keine gespeicherten Routen'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.add),
              label: const Text('Route planen'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final trip = routes[index];
        return _buildRouteTile(trip);
      },
    );
  }

  Widget _buildRouteTile(Trip trip) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.route, color: colorScheme.primary),
        ),
        title: Text(
          trip.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${trip.route.startAddress} → ${trip.route.endAddress}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.straighten, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '${trip.totalDistanceKm.toStringAsFixed(0)} km',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  trip.formattedTotalDuration,
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.place, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '${trip.stops.length} Stops',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmRemoveRoute(trip),
        ),
        onTap: () => _loadSavedRoute(trip),
      ),
    );
  }

  Widget _buildPOIsList(List<POI> pois) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (pois.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text('Keine favorisierten POIs'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/pois'),
              icon: const Icon(Icons.add),
              label: const Text('POIs entdecken'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pois.length,
      itemBuilder: (context, index) {
        final poi = pois[index];
        return _buildPOICard(poi);
      },
    );
  }

  Widget _buildPOICard(POI poi) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Enrichment triggern wenn kein Bild vorhanden
    if (poi.imageUrl == null && !_enrichedPOIIds.contains(poi.id)) {
      _enrichedPOIIds.add(poi.id);
      ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // POI zum State hinzufügen für POI-Detail-Screen
          ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
          context.push('/poi/${poi.id}');
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bild oder Platzhalter (mit CachedNetworkImage)
                Expanded(
                  flex: 2,
                  child: poi.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: poi.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildPOIPlaceholder(poi.categoryIcon),
                          errorWidget: (context, url, error) =>
                              _buildPOIPlaceholder(poi.categoryIcon),
                        )
                      : _buildPOIPlaceholder(poi.categoryIcon),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poi.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          poi.categoryLabel,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Favorit-Button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                  onPressed: () => _confirmRemovePOI(poi),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPOIPlaceholder(String icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  /// Laedt eine gespeicherte Route und zeigt sie auf der Karte an
  void _loadSavedRoute(Trip trip) {
    // Route-Daten pruefen
    if (trip.route.coordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route-Daten sind unvollständig')),
      );
      return;
    }

    // Bestehenden State zuruecksetzen
    ref.read(routePlannerProvider.notifier).clearRoute();
    ref.read(randomTripNotifierProvider.notifier).reset();

    // Route und Stops setzen (ohne OSRM-Neuberechnung)
    final stops = trip.stops.map((stop) => stop.toPOI()).toList();
    ref.read(tripStateProvider.notifier).setRouteAndStops(trip.route, stops);

    // Auto-Zoom auf Route aktivieren
    ref.read(shouldFitToRouteProvider.notifier).state = true;

    // Zur Karte navigieren
    context.go('/');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route "${trip.name}" geladen')),
    );
  }

  void _confirmRemoveRoute(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route entfernen?'),
        content: Text('Möchtest du "${trip.name}" aus den Favoriten entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(favoritesNotifierProvider.notifier).removeRoute(trip.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route entfernt')),
              );
            },
            child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmRemovePOI(POI poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('POI entfernen?'),
        content: Text('Möchtest du "${poi.name}" aus den Favoriten entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(favoritesNotifierProvider.notifier).removePOI(poi.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('POI entfernt')),
              );
            },
            child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Favoriten löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(favoritesNotifierProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alle Favoriten gelöscht')),
              );
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
