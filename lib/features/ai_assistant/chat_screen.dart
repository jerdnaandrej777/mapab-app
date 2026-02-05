import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/location_helper.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/weather_poi_utils.dart';
import '../../data/models/poi.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/poi_enrichment_service.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/poi_repo.dart';
import '../../data/repositories/trip_generator_repo.dart';
import '../../features/map/providers/route_session_provider.dart';
import '../../features/map/providers/weather_provider.dart';
import '../../features/map/widgets/weather_badge_unified.dart';
import '../../features/poi/providers/poi_state_provider.dart';
import '../../features/trip/providers/trip_state_provider.dart';
import 'widgets/chat_message.dart';
import 'widgets/suggestion_chips.dart';

/// AI-Chat-Screen
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

/// Message-Typ für unterschiedliche Chat-Inhalte
enum ChatMessageType { text, poiList }

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _backendAvailable = true;

  // GPS-Standort State
  LatLng? _currentLocation;
  String? _currentLocationName;
  bool _isLoadingLocation = false;

  // Such-Radius (10-100km)
  double _searchRadius = 30.0;

  // Wetter-Condition fuer Badge-Anzeige (cached)
  WeatherCondition? get _chatWeatherCondition {
    final state = ref.read(locationWeatherNotifierProvider);
    return state.hasWeather ? state.condition : null;
  }

  // Chat-Nachrichten mit History für Backend
  // Erweitert um POI-Liste Support
  final List<Map<String, dynamic>> _messages = [
    {
      'content':
          'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?',
      'isUser': false,
      'type': ChatMessageType.text,
    },
  ];

  List<String> get _suggestions {
    final weatherState = ref.read(locationWeatherNotifierProvider);
    final condition = weatherState.condition;
    if (condition == WeatherCondition.bad ||
        condition == WeatherCondition.danger) {
      return [
        '🏛️ Indoor-Tipps bei Regen',
        '📍 POIs in meiner Nähe',
        '🏰 Sehenswürdigkeiten',
        '🍽️ Restaurants',
      ];
    }
    if (condition == WeatherCondition.good) {
      return [
        '☀️ Outdoor-Highlights',
        '📍 POIs in meiner Nähe',
        '🌲 Natur & Parks',
        '🏰 Sehenswürdigkeiten',
      ];
    }
    return [
      '📍 POIs in meiner Nähe',
      '🏰 Sehenswürdigkeiten',
      '🌲 Natur & Parks',
      '🍽️ Restaurants',
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    _initializeLocation(); // GPS automatisch beim Start laden
  }

  /// GPS-Standort automatisch beim Chat-Start laden
  Future<void> _initializeLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final result = await LocationHelper.getCurrentPosition(
        accuracy: LocationAccuracy.medium,
      );

      if (!result.isSuccess) {
        debugPrint('[AI-Chat] GPS nicht verfuegbar: ${result.error}');
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      final location = result.position!;

      // Reverse Geocoding für Ortsname
      String? locationName;
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.reverseGeocode(location);
        if (result != null) {
          locationName = result.shortName ?? result.displayName;
        }
      } catch (e) {
        debugPrint('[AI-Chat] Reverse Geocoding Fehler: $e');
      }

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _currentLocationName = locationName ?? 'Mein Standort';
          _isLoadingLocation = false;
        });
        debugPrint(
            '[AI-Chat] Standort geladen: $_currentLocationName (${location.latitude}, ${location.longitude})');
      }
    } catch (e) {
      debugPrint('[AI-Chat] GPS Fehler: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// GPS-Dialog anzeigen wenn deaktiviert
  Future<bool> _showGpsDialog() async {
    return LocationHelper.showGpsDialog(context);
  }

  Future<void> _checkBackendHealth() async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final isHealthy = await aiService.checkHealth();
      if (mounted) {
        setState(() {
          _backendAvailable = isHealthy;
        });
      }
    } catch (e) {
      debugPrint('[AI-Chat] Backend Health-Check fehlgeschlagen: $e');
      if (mounted) {
        setState(() {
          _backendAvailable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('AI-Assistent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: 'Chat leeren',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner (nur wenn Backend nicht verfügbar)
          _buildStatusBanner(colorScheme),

          // Location Header mit Standort und Radius
          _buildLocationHeader(colorScheme),

          // Chat-Nachrichten
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return const ChatMessageBubble(
                          content: '',
                          isUser: false,
                          isLoading: true,
                        );
                      }

                      final message = _messages[index];
                      final messageType = message['type'] as ChatMessageType? ??
                          ChatMessageType.text;

                      // POI-Liste anzeigen
                      if (messageType == ChatMessageType.poiList) {
                        final pois = message['pois'] as List<POI>?;
                        final headerText = message['content'] as String?;
                        return _buildPOIListMessage(
                          pois: pois ?? [],
                          headerText: headerText,
                          colorScheme: colorScheme,
                        );
                      }

                      // Standard Text-Nachricht
                      return ChatMessageBubble(
                        content: message['content'],
                        isUser: message['isUser'],
                      );
                    },
                  ),
          ),

          // Vorschläge
          if (_messages.length <= 2)
            SuggestionChips(
              suggestions: _suggestions,
              onSelected: _handleSuggestionTap,
            ),

          // Eingabefeld
          _buildInputField(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colorScheme) {
    if (_backendAvailable) return const SizedBox.shrink();

    // Prüfe ob Backend überhaupt konfiguriert ist
    final isConfigured = ApiConfig.isConfigured;
    final message = isConfigured
        ? 'Demo-Modus: Backend nicht erreichbar'
        : 'Demo-Modus: Backend-URL nicht konfiguriert';

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13,
              ),
            ),
          ),
          if (isConfigured)
            TextButton(
              onPressed: _checkBackendHealth,
              child: const Text('Erneut prüfen'),
            ),
        ],
      ),
    );
  }

  /// Location Header mit Standort und Radius-Slider
  Widget _buildLocationHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Standort-Zeile
          Row(
            children: [
              // Standort-Info oder Loading
              if (_isLoadingLocation)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Standort wird geladen...',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else if (_currentLocation != null)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.green.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _currentLocationName ?? 'Standort aktiv',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    final serviceEnabled =
                        await LocationHelper.isServiceEnabled();
                    if (!serviceEnabled) {
                      final shouldOpen = await _showGpsDialog();
                      if (shouldOpen) {
                        await LocationHelper.openSettings();
                      }
                      return;
                    }
                    _initializeLocation();
                  },
                  icon: Icon(
                    Icons.location_off,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    'Standort aktivieren',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Radius-Anzeige
              if (_currentLocation != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_searchRadius.toInt()} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.tune,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _showRadiusSliderDialog,
                  tooltip: 'Such-Radius anpassen',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Dialog zum Anpassen des Such-Radius
  void _showRadiusSliderDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    double tempRadius = _searchRadius;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Such-Radius'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempRadius.toInt()} km',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempRadius,
                min: 10,
                max: 100,
                divisions: 9,
                label: '${tempRadius.toInt()} km',
                onChanged: (value) {
                  setDialogState(() {
                    tempRadius = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              // Quick-Select Buttons
              Wrap(
                spacing: 8,
                children: [15, 30, 50, 100].map((radius) {
                  final isSelected = tempRadius == radius.toDouble();
                  return ChoiceChip(
                    label: Text('$radius km'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        tempRadius = radius.toDouble();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _searchRadius = tempRadius;
                });
                Navigator.pop(context);
              },
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI-Reiseassistent',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Frag mich alles über deine Reise!',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(ColorScheme colorScheme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nachricht eingeben...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: colorScheme.onPrimary),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// POI-Liste als Chat-Nachricht anzeigen
  Widget _buildPOIListMessage({
    required List<POI> pois,
    String? headerText,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header-Text (z.B. "📍 POIs in deiner Nähe:")
        if (headerText != null && headerText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),

        // POI-Karten
        if (pois.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Keine POIs in diesem Bereich gefunden.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...pois.take(5).map((poi) => _buildPOICard(poi, colorScheme)),

        // "Mehr anzeigen" Button wenn > 5 POIs
        if (pois.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () {
                // Zur POI-Liste navigieren
                context.push('/pois');
              },
              icon: const Icon(Icons.list, size: 18),
              label: Text('Alle ${pois.length} POIs anzeigen'),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Einzelne POI-Karte (anklickbar)
  Widget _buildPOICard(POI poi, ColorScheme colorScheme) {
    // Distanz zum aktuellen Standort berechnen
    double? distanceKm;
    if (_currentLocation != null) {
      final Distance distance = const Distance();
      distanceKm = distance.as(
            LengthUnit.Kilometer,
            _currentLocation!,
            poi.location,
          ) /
          1000;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToPOI(poi),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // POI-Bild oder Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: poi.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: poi.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              _getCategoryIcon(poi.categoryId),
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              _getCategoryIcon(poi.categoryId),
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _getCategoryIcon(poi.categoryId),
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // POI-Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            poi.shortDescription ?? poi.categoryLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_chatWeatherCondition != null &&
                            _chatWeatherCondition != WeatherCondition.unknown &&
                            _chatWeatherCondition != WeatherCondition.mixed) ...[
                          const SizedBox(width: 6),
                          WeatherBadgeUnified.fromCategory(
                            condition: _chatWeatherCondition!,
                            category: poi.category,
                            size: WeatherBadgeSize.compact,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Distanz
              if (distanceKm != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              const SizedBox(width: 4),

              // Pfeil-Icon
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon für POI-Kategorie
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'museum':
        return Icons.museum;
      case 'castle':
        return Icons.castle;
      case 'church':
        return Icons.church;
      case 'monument':
        return Icons.account_balance;
      case 'nature':
        return Icons.park;
      case 'park':
        return Icons.nature_people;
      case 'lake':
        return Icons.water;
      case 'viewpoint':
        return Icons.landscape;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'city':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }

  /// Navigation zu POI-Details
  void _navigateToPOI(POI poi) {
    // POI zum State hinzufügen (damit POI-Detail-Screen ihn findet)
    ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);

    // Enrichment starten falls kein Bild
    if (poi.imageUrl == null) {
      ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
    }

    // Navigieren
    context.push('/poi/${poi.id}');
  }

  /// Prüft ob die Anfrage standortbasiert ist
  bool _isLocationBasedQuery(String query) {
    final lowerQuery = query.toLowerCase();
    final locationKeywords = [
      'in meiner nähe',
      'um mich',
      'hier',
      'in der nähe',
      'nearby',
      'nahegelegene',
      'pois in',
      'was gibt es',
      'was kann ich',
      'zeig mir',
      'empfehle',
      'indoor-tipps',
      'outdoor-highlight',
      'bei regen',
    ];

    return locationKeywords.any((k) => lowerQuery.contains(k));
  }

  /// Kategorien aus Anfrage-Text extrahieren
  List<String>? _getCategoriesFromQuery(String query) {
    final lowerQuery = query.toLowerCase();

    // Kategorie-Mapping (v1.7.9: ungueltige IDs gefixt + erweitert)
    // Gueltige IDs: castle, nature, museum, viewpoint, lake, coast, park,
    //               city, activity, hotel, restaurant, unesco, church, monument, attraction
    final categoryMapping = <String, List<String>>{
      'sehenswürd': ['museum', 'monument', 'castle', 'viewpoint', 'unesco'],
      'museum': ['museum'],
      'schloss': ['castle'],
      'schlösser': ['castle'],
      'burg': ['castle'],
      'kirche': ['church'],
      'natur': ['nature', 'park', 'lake', 'coast'],
      'park': ['park', 'nature'],
      'see': ['lake'],
      'restaurant': ['restaurant'],
      'essen': ['restaurant'],
      'hotel': ['hotel'],
      'übernacht': ['hotel'],
      'aussicht': ['viewpoint'],
      'kultur': ['museum', 'monument', 'church', 'castle', 'unesco'],
      'strand': ['coast'],
      'küste': ['coast'],
      'aktivität': ['activity'],
      'sport': ['activity'],
      'wandern': ['nature', 'viewpoint', 'park'],
      'familie': ['activity', 'park', 'museum'],
      'zoo': ['activity'],
      'freizeitpark': ['activity'],
      'therme': ['activity'],
      'stadt': ['city'],
      'indoor': ['museum', 'church', 'restaurant', 'hotel', 'castle', 'activity'],
      'outdoor': ['nature', 'park', 'lake', 'coast', 'viewpoint'],
      'regen': ['museum', 'church', 'restaurant', 'hotel', 'castle', 'activity'],
    };

    for (final entry in categoryMapping.entries) {
      if (lowerQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    // Standard: alle Kategorien
    return null;
  }

  /// Standortbasierte POI-Anfrage verarbeiten
  Future<void> _handleLocationBasedQuery(String query) async {
    // User-Nachricht hinzufügen
    setState(() {
      _messages.add({
        'content': query,
        'isUser': true,
        'type': ChatMessageType.text,
      });
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Standort prüfen
    if (_currentLocation == null) {
      // Versuche Standort zu laden
      await _initializeLocation();

      if (_currentLocation == null) {
        // Kein Standort verfügbar
        final serviceEnabled = await LocationHelper.isServiceEnabled();
        if (!serviceEnabled) {
          final shouldOpen = await _showGpsDialog();
          if (shouldOpen) {
            await LocationHelper.openSettings();
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _messages.add({
              'content':
                  '📍 **Standort nicht verfügbar**\n\n'
                  'Um POIs in deiner Nähe zu finden, benötige ich Zugriff auf deinen Standort.\n\n'
                  'Bitte aktiviere die Ortungsdienste und versuche es erneut.',
              'isUser': false,
              'type': ChatMessageType.text,
            });
          });
          _scrollToBottom();
        }
        return;
      }
    }

    try {
      debugPrint(
          '[AI-Chat] Suche POIs um ${_currentLocation!.latitude}, ${_currentLocation!.longitude} mit Radius ${_searchRadius}km');

      // Kategorien aus Anfrage extrahieren
      final categories = _getCategoriesFromQuery(query);

      // POIs laden
      final poiRepo = ref.read(poiRepositoryProvider);
      final pois = await poiRepo.loadPOIsInRadius(
        center: _currentLocation!,
        radiusKm: _searchRadius,
        categoryFilter: categories,
      );

      debugPrint('[AI-Chat] ${pois.length} POIs gefunden');

      if (!mounted) return;

      // POIs nach Distanz sortieren
      final Distance distanceCalculator = const Distance();
      var sortedPOIs = List<POI>.from(pois);
      sortedPOIs.sort((a, b) {
        final distA = distanceCalculator.as(
          LengthUnit.Kilometer,
          _currentLocation!,
          a.location,
        );
        final distB = distanceCalculator.as(
          LengthUnit.Kilometer,
          _currentLocation!,
          b.location,
        );
        return distA.compareTo(distB);
      });

      // Wetter-basierte Sekundaer-Sortierung
      final weatherState = ref.read(locationWeatherNotifierProvider);
      final chatWeatherCondition = weatherState.condition;
      if (chatWeatherCondition != WeatherCondition.unknown &&
          chatWeatherCondition != WeatherCondition.mixed) {
        sortedPOIs = WeatherPOIUtils.sortByWeatherRelevance(
          sortedPOIs,
          chatWeatherCondition,
        );
      }

      // Header-Text basierend auf Kategorien
      String headerText;
      if (categories != null && categories.isNotEmpty) {
        headerText =
            '📍 **${sortedPOIs.length} POIs** (${categories.join(", ")}) im Umkreis von ${_searchRadius.toInt()} km:';
      } else {
        headerText =
            '📍 **${sortedPOIs.length} POIs** im Umkreis von ${_searchRadius.toInt()} km:';
      }

      // POIs sofort anzeigen (mit Kategorie-Icons als Placeholder)
      setState(() {
        _isLoading = false;
        _messages.add({
          'content': headerText,
          'isUser': false,
          'type': ChatMessageType.poiList,
          'pois': sortedPOIs,
        });
      });
      _scrollToBottom();

      // OPTIMIERT v1.7.6: Hintergrund-Enrichment für Bilder im Chat
      // POIs werden sofort angezeigt, Bilder laden asynchron nach
      final messageIndex = _messages.length - 1;
      final poisToEnrich = sortedPOIs
          .where((p) => p.imageUrl == null && !p.isEnriched)
          .take(10)
          .toList();

      if (poisToEnrich.isNotEmpty) {
        debugPrint('[AI-Chat] Starte Hintergrund-Enrichment für ${poisToEnrich.length} POIs');
        final enrichmentService = ref.read(poiEnrichmentServiceProvider);
        final enrichedMap = await enrichmentService.enrichPOIsBatch(poisToEnrich);

        if (mounted && messageIndex < _messages.length) {
          // Bestehende Nachricht mit angereicherten POIs aktualisieren
          final updatedPOIs = sortedPOIs.map((poi) {
            return enrichedMap[poi.id] ?? poi;
          }).toList();

          setState(() {
            _messages[messageIndex] = {
              ..._messages[messageIndex],
              'pois': updatedPOIs,
            };
          });
          debugPrint('[AI-Chat] Hintergrund-Enrichment abgeschlossen - Bilder aktualisiert');
        }
      }
    } catch (e) {
      debugPrint('[AI-Chat] POI-Suche Fehler: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add({
            'content':
                '❌ **Fehler bei der POI-Suche**\n\n'
                'Entschuldigung, es gab ein Problem beim Laden der POIs.\n\n'
                'Bitte versuche es erneut.',
            'isUser': false,
            'type': ChatMessageType.text,
          });
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();

    // Prüfe ob standortbasierte Anfrage
    if (_isLocationBasedQuery(userMessage)) {
      await _handleLocationBasedQuery(userMessage);
      return;
    }

    setState(() {
      _messages.add({
        'content': userMessage,
        'isUser': true,
        'type': ChatMessageType.text,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Prüfe ob Backend verfügbar ist
      if (!_backendAvailable) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'content': _generateSmartDemoResponse(userMessage),
            'isUser': false,
            'type': ChatMessageType.text,
          });
        });
        _scrollToBottom();
        return;
      }

      // Echte API-Anfrage mit Chat-History
      final aiService = ref.read(aiServiceProvider);
      debugPrint('[AI-Chat] Sende Anfrage an Backend...');

      // Chat-History für Kontext aufbereiten
      final history = _messages
          .where((m) => m['content'] != null)
          .map((m) => ChatMessage(
                content: m['content'] as String,
                isUser: m['isUser'] as bool,
              ))
          .toList();

      // Trip-Kontext abrufen (mit Standort für standortbasierte Empfehlungen)
      final tripState = ref.read(tripStateProvider);
      final context = TripContext(
        route: tripState.route,
        stops: tripState.stops,
        userLatitude: _currentLocation?.latitude,
        userLongitude: _currentLocation?.longitude,
        userLocationName: _currentLocationName,
      );

      final response = await aiService.chat(
        message: userMessage,
        context: context,
        history: history.take(10).toList(), // Letzte 10 Nachrichten
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add({
          'content': response.isNotEmpty
              ? response
              : 'Entschuldigung, ich konnte keine Antwort generieren.',
          'isUser': false,
        });
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('[AI-Chat] Fehler: $e');

      if (!mounted) return;

      // Bei Fehler auf Demo-Modus wechseln
      setState(() {
        _backendAvailable = false;
        _isLoading = false;
        _messages.add({
          'content': _generateSmartDemoResponse(userMessage),
          'isUser': false,
        });
      });
      _scrollToBottom();
    }
  }

  /// Intelligente Demo-Antworten basierend auf Schlüsselwörtern
  String _generateSmartDemoResponse(String query) {
    final lowerQuery = query.toLowerCase();

    // Sehenswürdigkeiten
    if (lowerQuery.contains('sehenswürd') ||
        lowerQuery.contains('sightseeing') ||
        lowerQuery.contains('besichtigen')) {
      final tripState = ref.read(tripStateProvider);
      if (tripState.hasRoute && tripState.stops.isNotEmpty) {
        final stopList = tripState.stops
            .take(5)
            .map((s) => '• ${s.name} (${s.categoryLabel})')
            .join('\n');
        return '📍 **Sehenswürdigkeiten auf deiner Route:**\n\n'
            '$stopList\n\n'
            'Tippe auf einen Stop im Trip-Screen für Details!';
      }
      return '🗺️ **Top Sehenswürdigkeiten:**\n\n'
          '• 🏰 Schloss Neuschwanstein - Bayerns Märchenschloss\n'
          '• 🏔️ Zugspitze - Deutschlands höchster Gipfel\n'
          '• 🌲 Partnachklamm - Beeindruckende Schlucht\n'
          '• 🏛️ Marienplatz München - Historisches Zentrum\n\n'
          'Erstelle eine Route, um personalisierte Empfehlungen zu erhalten!';
    }

    // Natur
    if (lowerQuery.contains('natur') ||
        lowerQuery.contains('park') ||
        lowerQuery.contains('wald') ||
        lowerQuery.contains('see')) {
      return '🌲 **Naturhighlights:**\n\n'
          '• 🏞️ **Königssee** - Kristallklarer Bergsee\n'
          '• 🌲 **Nationalpark Berchtesgaden** - Unberührte Natur\n'
          '• 🏔️ **Partnachklamm** - Spektakuläre Schlucht\n'
          '• 🌳 **Englischer Garten** - Münchens grüne Oase\n\n'
          'Wähle "🤖 AI-Trip generieren" mit Interesse "Natur" für eine personalisierte Route!';
    }

    // Restaurants
    if (lowerQuery.contains('restaurant') ||
        lowerQuery.contains('essen') ||
        lowerQuery.contains('imbiss') ||
        lowerQuery.contains('küche')) {
      return '🍽️ **Restaurant-Empfehlungen:**\n\n'
          '• 🥨 **Hofbräuhaus München** - Bayerische Klassiker (4.5★)\n'
          '• 🍖 **Augustiner Bräustuben** - Traditionell & gemütlich (4.4★)\n'
          '• 🥗 **Prinz Myshkin** - Vegetarisch & modern (4.3★)\n\n'
          'Tipp: Nutze die POI-Liste mit Filter "Restaurant" für mehr Optionen!';
    }

    // Hotels
    if (lowerQuery.contains('hotel') ||
        lowerQuery.contains('übernacht') ||
        lowerQuery.contains('schlafen')) {
      return '🏨 **Unterkunft-Tipps:**\n\n'
          '• 🏨 Hotels findest du über die POI-Suche\n'
          '• 💡 Filtere nach "Hotel" in der POI-Liste\n'
          '• 📍 Auf der Karte siehst du Hotels in der Nähe\n\n'
          'Erstelle erst deine Route, dann zeige ich dir Hotels entlang des Weges!';
    }

    // Wetter
    if (lowerQuery.contains('wetter') ||
        lowerQuery.contains('regen') ||
        lowerQuery.contains('sonne')) {
      return '☀️ **Wetter-Info:**\n\n'
          'Aktuelle Wetterdaten siehst du:\n'
          '• 🗺️ Auf dem Map-Screen oben\n'
          '• 🎯 Bei POIs mit Outdoor-Aktivitäten\n\n'
          'Tipp: Bei Regen empfehle ich Museen und Indoor-Attraktionen!';
    }

    // Route
    if (lowerQuery.contains('route') ||
        lowerQuery.contains('fahrt') ||
        lowerQuery.contains('weg')) {
      final tripState = ref.read(tripStateProvider);
      if (tripState.hasRoute) {
        return '🛣️ **Deine aktuelle Route:**\n\n'
            '📍 Start: ${tripState.route!.startAddress}\n'
            '🎯 Ziel: ${tripState.route!.endAddress}\n'
            '📏 Distanz: ${tripState.route!.distanceKm.toStringAsFixed(0)} km\n'
            '⏱️ Fahrzeit: ${(tripState.route!.durationMinutes / 60).toStringAsFixed(1)}h\n'
            '🎯 Stops: ${tripState.stops.length}\n\n'
            'Gehe zum Trip-Screen für Details!';
      }
      return '🗺️ **Route erstellen:**\n\n'
          '1. Gehe zum 🗺️ Karten-Screen\n'
          '2. Tippe auf Start- und Zielpunkt\n'
          '3. Oder nutze "🤖 AI-Trip generieren"\n\n'
          'Dann kann ich dir Empfehlungen entlang der Route geben!';
    }

    // Hilfe
    if (lowerQuery.contains('hilfe') ||
        lowerQuery.contains('help') ||
        lowerQuery.contains('kannst du') ||
        lowerQuery.contains('was kann')) {
      return '🤖 **Was ich kann:**\n\n'
          '• 🗺️ Routen-Infos geben\n'
          '• 📍 Sehenswürdigkeiten empfehlen\n'
          '• 🌲 Naturhighlights zeigen\n'
          '• 🍽️ Restaurants vorschlagen\n'
          '• 🤖 AI-Trips generieren\n\n'
          'Frag mich einfach oder wähle einen Vorschlag unten!';
    }

    // Städte-spezifisch
    final cities = ['münchen', 'berlin', 'hamburg', 'köln', 'prag', 'wien', 'salzburg'];
    for (final city in cities) {
      if (lowerQuery.contains(city)) {
        return '🏙️ **$city erkunden:**\n\n'
            'Nutze "🤖 AI-Trip generieren" und gib "$city" als Ziel ein!\n\n'
            'Dort kannst du:\n'
            '• 📅 Anzahl der Tage wählen\n'
            '• ❤️ Interessen angeben (Kultur, Natur, Essen...)\n'
            '• 🚗 Eine optimierte Route erhalten\n\n'
            'Oder gehe zur POI-Liste und suche nach "$city"!';
      }
    }

    // Default-Antwort
    return '🤔 **Interessante Frage!**\n\n'
        'Im vollständigen Modus mit Backend-Verbindung kann ich dir hier eine detaillierte Antwort geben.\n\n'
        '**Probiere diese Funktionen:**\n'
        '• 🤖 AI-Trip generieren (Button unten)\n'
        '• 🗺️ Route auf der Karte erstellen\n'
        '• 📍 POI-Liste durchsuchen\n\n'
        '_Tipp: Frage nach Sehenswürdigkeiten, Restaurants oder Natur!_';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat leeren?'),
        content: const Text('Die gesamte Konversation wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _messages.add({
                  'content':
                      'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?',
                  'isUser': false,
                });
              });
            },
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }

  void _handleSuggestionTap(String suggestion) {
    switch (suggestion) {
      case '📍 POIs in meiner Nähe':
        _handleLocationBasedQuery('Zeig mir POIs in meiner Nähe');
        break;
      case '🏰 Sehenswürdigkeiten':
        _handleLocationBasedQuery('Zeig mir Sehenswürdigkeiten in meiner Nähe');
        break;
      case '🌲 Natur & Parks':
        _handleLocationBasedQuery('Zeig mir Natur und Parks in meiner Nähe');
        break;
      case '🍽️ Restaurants':
        _handleLocationBasedQuery('Zeig mir Restaurants in meiner Nähe');
        break;
      default:
        _sendMessage(suggestion);
    }
  }

  void _handleSehenswuerdigkeitenRequest() {
    final tripState = ref.read(tripStateProvider);

    if (tripState.hasRoute && tripState.stops.isNotEmpty) {
      // Zeige aktuelle Stops
      final stopList = tripState.stops
          .map((s) => '• **${s.name}** (${s.categoryLabel})')
          .join('\n');

      setState(() {
        _messages.add({
          'content': '🗺️ Zeige mir Sehenswürdigkeiten auf meiner Route',
          'isUser': true,
        });
        _messages.add({
          'content': '📍 **Sehenswürdigkeiten auf deiner Route:**\n\n'
              '$stopList\n\n'
              '💡 Gehe zum Trip-Screen für Details oder tippe auf einen POI!',
          'isUser': false,
        });
      });
      _scrollToBottom();
    } else if (tripState.hasRoute) {
      // Route vorhanden, aber keine Stops
      setState(() {
        _messages.add({
          'content': '🗺️ Zeige mir Sehenswürdigkeiten auf meiner Route',
          'isUser': true,
        });
        _messages.add({
          'content': '📍 **Noch keine Stops auf deiner Route!**\n\n'
              'Deine Route:\n'
              '• Start: ${tripState.route!.startAddress}\n'
              '• Ziel: ${tripState.route!.endAddress}\n\n'
              '💡 Gehe zur POI-Liste und füge Sehenswürdigkeiten hinzu!',
          'isUser': false,
        });
      });
      _scrollToBottom();
    } else {
      // Keine Route
      setState(() {
        _messages.add({
          'content': '🗺️ Zeige mir Sehenswürdigkeiten auf meiner Route',
          'isUser': true,
        });
        _messages.add({
          'content': '🗺️ **Erstelle zuerst eine Route!**\n\n'
              '1. Gehe zum Karten-Screen 🗺️\n'
              '2. Wähle Start- und Zielpunkt\n'
              '3. Oder nutze "🤖 AI-Trip generieren"\n\n'
              'Dann zeige ich dir alle Sehenswürdigkeiten entlang deiner Route!',
          'isUser': false,
        });
      });
      _scrollToBottom();
    }
  }

  void _handleNaturhighlightsRequest() {
    setState(() {
      _messages.add({
        'content': '🌲 Zeige mir Naturhighlights',
        'isUser': true,
      });
      _messages.add({
        'content': '🌲 **Naturhighlights entdecken:**\n\n'
            '**Top Empfehlungen:**\n'
            '• 🏞️ Königssee - Kristallklarer Bergsee\n'
            '• 🏔️ Partnachklamm - Spektakuläre Schlucht\n'
            '• 🌳 Nationalpark Berchtesgaden\n'
            '• 🏔️ Zugspitze - Deutschlands höchster Gipfel\n\n'
            '💡 **Tipp:** Gehe zur POI-Liste und filtere nach "Natur" 🌲\n\n'
            'Oder generiere einen AI-Trip mit Interesse "Natur"!',
        'isUser': false,
      });
    });
    _scrollToBottom();
  }

  void _handleRestaurantRequest() {
    setState(() {
      _messages.add({
        'content': '🍽️ Empfehle mir Restaurants',
        'isUser': true,
      });
      _messages.add({
        'content': '🍽️ **Restaurant-Empfehlungen:**\n\n'
            '**Bayerische Klassiker:**\n'
            '• 🥨 Hofbräuhaus München (4.5★)\n'
            '• 🍖 Augustiner Bräustuben (4.4★)\n\n'
            '**Modern & International:**\n'
            '• 🥗 Prinz Myshkin - Vegetarisch (4.3★)\n'
            '• 🍝 Brenner - Italienisch (4.2★)\n\n'
            '💡 **Tipp:** Nutze die POI-Liste mit Filter "Restaurant" für Lokale auf deiner Route!\n\n'
            'Oder frag mich nach einem bestimmten Küchenstil!',
        'isUser': false,
      });
    });
    _scrollToBottom();
  }

  void _showTripGeneratorDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final destinationController = TextEditingController();
    final startController = TextEditingController();
    double days = 3;
    final selectedInterests = <String>{};

    final interests = [
      'Kultur',
      'Natur',
      'Geschichte',
      'Essen',
      'Nightlife',
      'Shopping',
      'Sport',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🤖 AI-Trip generieren'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ziel (optional für Random Route)
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Ziel (optional)',
                    hintText: 'Leer = Zufällige Route um Startpunkt',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),

                // Startpunkt (optional - GPS-Fallback)
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Startpunkt (optional)',
                    hintText: 'Leer = GPS-Standort verwenden',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 16),

                // Tage
                Text(
                  'Anzahl Tage',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${days.round()} ${days.round() == 1 ? "Tag" : "Tage"}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Slider(
                  value: days,
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '${days.round()} Tage',
                  onChanged: (value) {
                    setDialogState(() {
                      days = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Interessen
                Text(
                  'Interessen:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: interests.map((interest) {
                    final isSelected = selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedInterests.add(interest);
                          } else {
                            selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final destination = destinationController.text.trim();
                final startText = startController.text.trim();
                final interestsList = selectedInterests.toList();
                final daysInt = days.round();

                // Dialog schließen
                Navigator.pop(context);

                // HYBRID-LOGIK:
                // Wenn Ziel angegeben → AI-Text-Plan (wie bisher)
                // Wenn Ziel leer → Random Route um Startpunkt/GPS

                if (destination.isNotEmpty) {
                  // ============ MIT ZIEL: AI-Text-Plan ============
                  _generateTrip(
                    destination: destination,
                    days: daysInt,
                    interests: interestsList,
                    startLocation: startText.isNotEmpty ? startText : null,
                  );
                } else {
                  // ============ OHNE ZIEL: Random Route ============
                  // Standort ermitteln (manuell oder GPS)
                  final location = await _getLocationIfNeeded(
                    startText.isNotEmpty ? startText : null,
                  );

                  if (location == null) {
                    // Fehler wurde bereits in _getLocationIfNeeded angezeigt
                    setState(() {
                      _messages.add({
                        'content':
                            '❌ Konnte keinen Standort ermitteln.\n\n'
                            'Bitte gib einen Startpunkt ein oder aktiviere GPS.',
                        'isUser': false,
                      });
                    });
                    return;
                  }

                  // Random Trip generieren
                  await _generateRandomTripFromLocation(
                    lat: location.lat,
                    lng: location.lng,
                    address: location.address,
                    interests: interestsList,
                    days: daysInt,
                  );
                }
              },
              child: const Text('Generieren'),
            ),
          ],
        ),
      ),
    ).then((_) {
      destinationController.dispose();
      startController.dispose();
    });
  }

  Future<void> _generateTrip({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
  }) async {
    // User-Nachricht hinzufügen
    setState(() {
      _messages.add({
        'content':
            'Generiere einen $days-Tage Trip nach $destination\n${interests.isNotEmpty ? "Interessen: ${interests.join(', ')}" : ""}',
        'isUser': true,
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      if (!_backendAvailable) {
        // Demo-Response
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'content': _generateDemoTripPlan(destination, days, interests),
            'isUser': false,
          });
        });
        _scrollToBottom();
        return;
      }

      final aiService = ref.read(aiServiceProvider);

      // Echte AI-Anfrage
      final plan = await aiService.generateTripPlan(
        destination: destination,
        days: days,
        interests: interests,
        startLocation: startLocation,
      );

      if (!mounted) return;

      // Formatiere den Plan
      final planText = StringBuffer();
      planText.writeln('🗺️ ${plan.title}\n');
      if (plan.description != null && plan.description!.isNotEmpty) {
        planText.writeln('${plan.description}\n');
      }

      for (var day in plan.days) {
        planText.writeln('**${day.title}**');
        if (day.description != null) {
          planText.writeln(day.description);
        }
        for (var stop in day.stops) {
          planText.writeln(
              '• ${stop.name} ${stop.duration != null ? "(${stop.duration})" : ""}');
          if (stop.description != null) {
            planText.writeln('  ${stop.description}');
          }
        }
        planText.writeln();
      }

      setState(() {
        _isLoading = false;
        _messages.add({
          'content': planText.toString(),
          'isUser': false,
        });
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('[Trip Generator] Fehler: $e');

      if (!mounted) return;

      // Bei Fehler Demo-Modus aktivieren
      setState(() {
        _backendAvailable = false;
        _isLoading = false;
        _messages.add({
          'content': _generateDemoTripPlan(destination, days, interests),
          'isUser': false,
        });
      });
      _scrollToBottom();
    }
  }

  /// GPS-Standort oder Geocoding für manuelle Eingabe abrufen
  Future<({double lat, double lng, String address})?> _getLocationIfNeeded(
      String? startText) async {
    // Wenn manueller Text eingegeben, Geocoding verwenden
    if (startText != null && startText.isNotEmpty) {
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final results = await geocodingRepo.geocode(startText);
        if (results.isNotEmpty) {
          final result = results.first;
          return (
            lat: result.location.latitude,
            lng: result.location.longitude,
            address: result.displayName ?? startText
          );
        }
      } catch (e) {
        debugPrint('[AI-Trip] Geocoding Fehler: $e');
      }
      return null;
    }

    // GPS-Standort abfragen
    final gpsResult = await LocationHelper.getCurrentPosition(
      accuracy: LocationAccuracy.medium,
    );

    if (!gpsResult.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gpsResult.message ?? 'GPS-Fehler')),
        );
      }
      return null;
    }

    final position = gpsResult.position!;

    // Reverse Geocoding für Adresse
    String address = 'Mein Standort';
    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final result = await geocodingRepo.reverseGeocode(position);
      if (result != null) {
        address = result.shortName ?? result.displayName ?? address;
      }
    } catch (e) {
      debugPrint('[AI-Trip] Reverse Geocoding Fehler: $e');
    }

    return (lat: position.latitude, lng: position.longitude, address: address);
  }

  /// Interessen-Liste zu POI-Kategorien mappen
  List<POICategory> _mapInterestsToCategories(List<String> interests) {
    final mapping = <String, List<String>>{
      'Kultur': ['museum', 'monument', 'unesco'],
      'Natur': ['nature', 'park', 'lake', 'viewpoint'],
      'Geschichte': ['castle', 'church', 'monument'],
      'Essen': ['restaurant'],
      'Nightlife': ['city'],
      'Shopping': ['city'],
      'Sport': ['activity'],
    };

    final categoryIds = <String>{};
    for (final interest in interests) {
      final ids = mapping[interest];
      if (ids != null) {
        categoryIds.addAll(ids);
      }
    }

    // Wenn keine Interessen gewählt, alle Kategorien verwenden (außer Hotel)
    if (categoryIds.isEmpty) {
      return POICategory.values
          .where((c) => c != POICategory.hotel)
          .toList();
    }

    return POICategory.values
        .where((c) => categoryIds.contains(c.id))
        .toList();
  }

  /// Random Trip generieren und an Trip-Screen übergeben
  Future<void> _generateRandomTripFromLocation({
    required double lat,
    required double lng,
    required String address,
    required List<String> interests,
    required int days,
  }) async {
    // User-Nachricht hinzufügen
    setState(() {
      _messages.add({
        'content':
            '🎲 Generiere zufällige Route um "$address"\n'
            '${interests.isNotEmpty ? "Interessen: ${interests.join(', ')}" : "Alle Kategorien"}',
        'isUser': true,
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Interessen zu Kategorien mappen
      final categories = _mapInterestsToCategories(interests);

      // TripGenerator aufrufen
      final tripGenerator = ref.read(tripGeneratorRepositoryProvider);
      final result = await tripGenerator.generateDayTrip(
        startLocation: LatLng(lat, lng),
        startAddress: address,
        radiusKm: days == 1 ? 100 : (days * 80).clamp(100, 300).toDouble(),
        categories: categories,
        poiCount: (days * 3).clamp(3, 8),
      );

      if (!mounted) return;

      // Erfolgsmeldung im Chat
      setState(() {
        _isLoading = false;
        _messages.add({
          'content':
              '✅ Route generiert!\n\n'
              '📍 **${result.trip.name}**\n'
              '📏 ${result.trip.route.distanceKm.toStringAsFixed(0)} km\n'
              '⏱️ ${(result.trip.route.durationMinutes / 60).toStringAsFixed(1)}h Fahrzeit\n'
              '🎯 ${result.selectedPOIs.length} Stops\n\n'
              'Öffne Trip-Screen...',
          'isUser': false,
        });
      });
      _scrollToBottom();

      // Alte Route-Session stoppen und POIs löschen
      ref.read(routeSessionProvider.notifier).stopRoute();
      ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
      debugPrint('[AI-Chat] Alte Route-Session und POIs gelöscht');

      // Route an TripStateProvider übergeben
      final tripState = ref.read(tripStateProvider.notifier);
      tripState.setRoute(result.trip.route);
      tripState.setStops(result.selectedPOIs);

      // Kurz warten, dann zum Trip-Screen navigieren
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/trip');
      }
    } catch (e) {
      debugPrint('[AI-Trip] Random Trip Fehler: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add({
          'content':
              '❌ Fehler beim Generieren der Route:\n$e\n\n'
              'Bitte versuche es erneut oder gib ein konkretes Ziel ein.',
          'isUser': false,
        });
      });
      _scrollToBottom();
    }
  }

  String _generateDemoTripPlan(String destination, int days, List<String> interests) {
    final interestsText = interests.isNotEmpty
        ? 'Basierend auf deinen Interessen (${interests.join(', ')}):\n\n'
        : '';

    return '🗺️ **$days Tage in $destination**\n\n'
        '$interestsText'
        '**Tag 1: Ankunft & Stadterkundung**\n'
        '• Hauptbahnhof (1h) - Ankunft und Check-in\n'
        '• Altstadt (2h) - Historisches Zentrum erkunden\n'
        '• Stadtmuseum (1.5h) - Geschichte kennenlernen\n\n'
        '**Tag 2: Kultur & Sehenswürdigkeiten**\n'
        '• Schloss/Burg (2h) - Wahrzeichen der Stadt\n'
        '• Kunstgalerie (1.5h) - Lokale Kunstszene\n'
        '• Lokales Restaurant (1h) - Traditionelle Küche\n\n'
        '${days > 2 ? "**Tag 3: Natur & Entspannung**\n• Park/Garten (2h) - Grüne Oase\n• Aussichtspunkt (1h) - Panoramablick\n• Café (1h) - Kaffee und Kuchen\n\n" : ""}'
        '💡 _Dies ist ein Demo-Plan. Mit Backend-Verbindung erhältst du personalisierte Empfehlungen!_\n\n'
        '**Tipp:** Nutze "AI-Trip generieren" ohne Ziel für eine echte Route mit POIs!';
  }
}
