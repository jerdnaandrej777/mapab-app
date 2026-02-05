import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/route.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../map/providers/route_planner_provider.dart';

/// Suchscreen für Start/Ziel-Eingabe
class SearchScreen extends ConsumerStatefulWidget {
  final bool isStartLocation;

  const SearchScreen({
    super.key,
    this.isStartLocation = false,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<AutocompleteSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Automatisch Fokus setzen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.autocomplete(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Search] Fehler bei Geocoding: $e');

      // Fallback: Zeige lokale Vorschläge für deutsche Städte
      final localResults = _getLocalSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = localResults;
          _isLoading = false;
        });

        // Zeige Hinweis, wenn keine Netzwerkverbindung
        if (localResults.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein Internet - Zeige lokale Vorschläge'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Lokale Vorschläge für deutsche Städte (Fallback ohne Internet)
  List<AutocompleteSuggestion> _getLocalSuggestions(String query) {
    final q = query.toLowerCase();
    final cities = {
      'münchen': LatLng(48.1351, 11.5820),
      'berlin': LatLng(52.5200, 13.4050),
      'hamburg': LatLng(53.5511, 9.9937),
      'köln': LatLng(50.9375, 6.9603),
      'frankfurt': LatLng(50.1109, 8.6821),
      'stuttgart': LatLng(48.7758, 9.1829),
      'düsseldorf': LatLng(51.2277, 6.7735),
      'dortmund': LatLng(51.5136, 7.4653),
      'essen': LatLng(51.4556, 7.0116),
      'leipzig': LatLng(51.3397, 12.3731),
      'bremen': LatLng(53.0793, 8.8017),
      'dresden': LatLng(51.0504, 13.7373),
      'hannover': LatLng(52.3759, 9.7320),
      'nürnberg': LatLng(49.4521, 11.0767),
      'duisburg': LatLng(51.4344, 6.7623),
    };

    return cities.entries
        .where((e) => e.key.contains(q))
        .map((e) => AutocompleteSuggestion(
              displayName: '${e.key.substring(0, 1).toUpperCase()}${e.key.substring(1)}, Deutschland',
              location: e.value,
              icon: '🏙️',
            ))
        .toList();
  }

  Future<void> _selectSuggestion(AutocompleteSuggestion suggestion) async {
    // Geocoding wenn keine Koordinaten vorhanden
    LatLng? location = suggestion.location;

    if (location == null && suggestion.placeId != null) {
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.geocode(suggestion.displayName);
        if (result.isNotEmpty) {
          location = result.first.location;
        }
      } catch (e) {
        debugPrint('[Search] Fehler beim Geocoding: $e');
      }
    }

    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Standort konnte nicht gefunden werden')),
        );
      }
      return;
    }

    // In RoutePlanner State speichern
    final routePlanner = ref.read(routePlannerProvider.notifier);
    if (widget.isStartLocation) {
      routePlanner.setStart(location, suggestion.displayName);
    } else {
      routePlanner.setEnd(location, suggestion.displayName);
    }

    // Zurück navigieren
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStartLocation ? 'Start wählen' : 'Ziel wählen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Suchfeld
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.isStartLocation
                    ? 'Startpunkt suchen...'
                    : 'Ziel suchen...',
                prefixIcon: Icon(
                  widget.isStartLocation ? Icons.trip_origin : Icons.place,
                  color: widget.isStartLocation
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Ergebnisliste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty
                    ? _buildEmptyState()
                    : _buildSuggestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Ort eingeben zum Suchen',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Ergebnisse gefunden',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _SuggestionTile(
          suggestion: suggestion,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }
}

/// Einzelne Vorschlag-Zeile
class _SuggestionTile extends StatelessWidget {
  final AutocompleteSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            suggestion.icon ?? '📍',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        _getTitle(suggestion.displayName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _getSubtitle(suggestion.displayName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.north_west, size: 18),
      onTap: onTap,
    );
  }

  String _getTitle(String displayName) {
    final parts = displayName.split(',');
    return parts.isNotEmpty ? parts[0].trim() : displayName;
  }

  String _getSubtitle(String displayName) {
    final parts = displayName.split(',');
    if (parts.length > 1) {
      return parts.sublist(1).join(',').trim();
    }
    return '';
  }
}
