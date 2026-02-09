import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/location_helper.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/weather_poi_utils.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/poi_social_repo.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/poi_enrichment_service.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/poi_repo.dart';
import '../../data/repositories/trip_generator_repo.dart';
import '../../features/map/providers/route_session_provider.dart';
import '../../features/map/providers/weather_provider.dart';
import '../../features/map/providers/map_controller_provider.dart';
import '../../features/map/widgets/weather_badge_unified.dart';
import '../../features/poi/providers/poi_state_provider.dart';
import '../../features/trip/providers/trip_state_provider.dart';
import 'chat_models.dart';
import 'widgets/chat_message.dart';
import 'widgets/suggestion_chips.dart';

/// AI-Chat-Screen
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _backendAvailable = true;
  int _requestCounter = 0;
  ChatRequestToken? _activeRequest;
  final Map<String, List<ChatMessage>> _tripScopedHistory = {};
  int _healthFailureCount = 0;

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

  // Chat-Nachrichten mit History fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r Backend
  // Erweitert um POI-Liste Support
  final List<ChatUiMessage> _messages = [];
  bool _welcomeMessageAdded = false;

  List<String> _getSuggestions(BuildContext context) {
    final weatherState = ref.read(locationWeatherNotifierProvider);
    final condition = weatherState.condition;
    if (condition == WeatherCondition.bad ||
        condition == WeatherCondition.danger) {
      return [
        context.l10n.chatIndoorTips,
        context.l10n.chatPoisNearMe,
        context.l10n.chatAttractions,
        context.l10n.chatRestaurants,
        'Hotels in der Naehe',
      ];
    }
    if (condition == WeatherCondition.good) {
      return [
        context.l10n.chatOutdoorHighlights,
        context.l10n.chatPoisNearMe,
        context.l10n.chatNatureParks,
        context.l10n.chatRestaurants,
        'Hotels in der Naehe',
      ];
    }
    return [
      context.l10n.chatPoisNearMe,
      context.l10n.chatAttractions,
      context.l10n.chatNatureParks,
      context.l10n.chatRestaurants,
      'Hotels in der Naehe',
    ];
  }

  ChatRequestToken _startRequest(ChatRequestKind kind) {
    final token = ChatRequestToken(id: ++_requestCounter, kind: kind);
    _activeRequest = token;
    return token;
  }

  bool _isCurrentRequest(ChatRequestToken token) {
    return _activeRequest?.id == token.id;
  }

  void _finishRequest(ChatRequestToken token) {
    if (_isCurrentRequest(token)) {
      _activeRequest = null;
    }
  }

  String _activeTripKey() {
    final tripState = ref.read(tripStateProvider);
    if (!tripState.hasRoute || tripState.route == null) {
      return 'no_route';
    }

    final route = tripState.route!;
    final stopIds = tripState.stops.take(15).map((s) => s.id).join(',');
    return '${route.startAddress}|${route.endAddress}|$stopIds';
  }

  void _rememberTripMessage({
    required String content,
    required bool isUser,
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) return;

    final key = _activeTripKey();
    final history = _tripScopedHistory.putIfAbsent(key, () => <ChatMessage>[]);
    history.add(ChatMessage(content: normalized, isUser: isUser));
    if (history.length > 20) {
      history.removeRange(0, history.length - 20);
    }
  }

  void _addTextMessage({
    required String content,
    required bool isUser,
  }) {
    _messages.add(TextMessage(content: content, isUser: isUser));
  }

  void _addSystemMessage({
    required String content,
    List<CopilotAction> actions = const [],
  }) {
    _messages.add(SystemMessage(content: content, actions: actions));
  }

  void _addPoiListMessage({
    required String content,
    required List<POI> pois,
    Map<String, AiPoiMeta> aiMeta = const {},
  }) {
    _messages.add(PoiListMessage(content: content, pois: pois, aiMeta: aiMeta));
  }

  void _maybeAddCopilotCard({
    required String sourceQuery,
    List<POI> suggestedPOIs = const [],
  }) {
    final weatherState = ref.read(locationWeatherNotifierProvider);
    final tripState = ref.read(tripStateProvider);
    final lower = _normalizeText(sourceQuery);

    if (weatherState.condition == WeatherCondition.bad ||
        weatherState.condition == WeatherCondition.danger) {
      _addSystemMessage(
        content:
            'Schlechtes Wetter erkannt. Ich kann dir eine Indoor-Alternative fuer die naechsten Stops anzeigen.',
        actions: const [
          CopilotAction(
              id: 'indoor_alternatives', label: 'Indoor-Alternativen'),
          CopilotAction(id: 'shorter_day', label: 'Kuerzere Tagesetappe'),
        ],
      );
      return;
    }

    if (tripState.hasRoute && tripState.route!.durationMinutes >= 360) {
      _addSystemMessage(
        content:
            'Die aktuelle Route ist lang. Ich kann die Etappe kuerzen oder einen Essensstopp entlang der Route vorschlagen.',
        actions: const [
          CopilotAction(id: 'shorter_day', label: 'Etappe kuerzen'),
          CopilotAction(id: 'food_stop_30km', label: 'Essensstopp in 30 km'),
        ],
      );
      return;
    }

    if (suggestedPOIs.isNotEmpty && !lower.contains('alternative')) {
      _addSystemMessage(
        content:
            'Willst du statt der aktuellen Vorschlaege auch alternative Highlights vergleichen?',
        actions: const [
          CopilotAction(
              id: 'compare_alternatives', label: 'Alternativen vergleichen'),
        ],
      );
    }
  }

  Future<void> _runCopilotAction(String actionId) async {
    switch (actionId) {
      case 'indoor_alternatives':
        await _handleLocationBasedQuery(
            'Zeig mir Indoor-Tipps bei Regen in meiner Naehe');
        break;
      case 'shorter_day':
        await _sendMessage(
            'Bitte schlage eine kuerzere Tagesetappe fuer meine aktuelle Route vor.');
        break;
      case 'food_stop_30km':
        await _handleLocationBasedQuery(
            'Empfiehl mir einen Essensstopp in meiner Naehe');
        break;
      case 'compare_alternatives':
        await _sendMessage(
            'Bitte gib mir eine Alternative zu den aktuellen Empfehlungen.');
        break;
      default:
        await _sendMessage(
            'Bitte hilf mir bei der Optimierung meiner aktuellen Route.');
    }
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

      // Reverse Geocoding fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r Ortsname
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
          _currentLocationName = locationName;
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
      _healthFailureCount = isHealthy ? 0 : _healthFailureCount + 1;
      if (mounted) {
        setState(() {
          if (isHealthy) {
            _backendAvailable = true;
          } else if (_healthFailureCount >= 2) {
            _backendAvailable = false;
          }
        });
      }
    } catch (e) {
      debugPrint('[AI-Chat] Backend Health-Check fehlgeschlagen: $e');
      _healthFailureCount++;
      if (mounted) {
        setState(() {
          if (_healthFailureCount >= 2) {
            _backendAvailable = false;
          }
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

    // Add welcome message on first build (needs context for l10n)
    if (!_welcomeMessageAdded) {
      _welcomeMessageAdded = true;
      _messages.add(TextMessage(
        content: context.l10n.chatWelcome,
        isUser: false,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 24),
            const SizedBox(width: 8),
            Text(context.l10n.chatTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: context.l10n.chatClear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner (nur wenn Backend nicht verfÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼gbar)
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

                      if (message is PoiListMessage) {
                        return _buildPOIListMessage(
                          pois: message.pois,
                          headerText: message.content,
                          colorScheme: colorScheme,
                          aiMeta: message.aiMeta,
                        );
                      }

                      if (message is SystemMessage) {
                        return _buildSystemMessageCard(
                          message: message,
                          colorScheme: colorScheme,
                        );
                      }

                      return ChatMessageBubble(
                        content: message.content,
                        isUser: message.isUser,
                      );
                    },
                  ),
          ),

          // VorschlÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¤ge
          if (_messages.length <= 2)
            SuggestionChips(
              suggestions: _getSuggestions(context),
              onSelected: (value) => _handleSuggestionTap(value),
            ),

          // Eingabefeld
          _buildInputField(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colorScheme) {
    if (_backendAvailable) return const SizedBox.shrink();

    // PrÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼fe ob Backend ÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼berhaupt konfiguriert ist
    final isConfigured = ApiConfig.isConfigured;
    final message = isConfigured
        ? context.l10n.chatDemoBackendNotReachable
        : context.l10n.chatDemoBackendNotConfigured;

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
              child: Text(context.l10n.chatCheckAgain),
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
                      context.l10n.chatLocationLoading,
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
                          _currentLocationName ??
                              context.l10n.chatLocationActive,
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
                    context.l10n.chatLocationEnable,
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
                  tooltip: context.l10n.chatRadiusAdjust,
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
    final l10n = context.l10n;
    double tempRadius = _searchRadius;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.chatSearchRadius),
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
                runSpacing: 8,
                children: [15, 30, 50, 100].map((radius) {
                  final isSelected = tempRadius == radius.toDouble();
                  return ChoiceChip(
                    label: Text(
                      '$radius km',
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.65),
                    selectedColor: colorScheme.primaryContainer,
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    showCheckmark: true,
                    checkmarkColor: colorScheme.primary,
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
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _searchRadius = tempRadius;
                });
                Navigator.pop(context);
              },
              child: Text(l10n.chatAccept),
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
            context.l10n.chatTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.chatWelcomeSubtitle,
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
                  hintText: context.l10n.chatInputHint,
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
    Map<String, AiPoiMeta> aiMeta = const {},
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header-Text (z.B. "ÃƒÂƒÃ‚Â°ÃƒÂ…Ã‚Â¸ÃƒÂ¢Ã¢Â‚Â¬Ã…Â“ÃƒÂ‚Ã‚Â POIs in deiner NÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¤he:")
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
                  context.l10n.chatNoPoisFound,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...pois
              .take(8)
              .map((poi) => _buildPOICard(poi, colorScheme, aiMeta[poi.id])),

        // "Mehr anzeigen" Button wenn > 8 POIs
        if (pois.length > 8)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () {
                // Zur POI-Liste navigieren
                context.push('/pois');
              },
              icon: const Icon(Icons.list, size: 18),
              label: Text(context.l10n.chatShowAllPois(pois.length)),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSystemMessageCard({
    required SystemMessage message,
    required ColorScheme colorScheme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'AI Copilot',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
            if (message.actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: message.actions
                      .map(
                        (action) => OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _runCopilotAction(action.id),
                          child: Text(action.label),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Einzelne POI-Karte (anklickbar)
  Widget _buildPOICard(
    POI poi,
    ColorScheme colorScheme,
    AiPoiMeta? aiMeta,
  ) {
    // Distanz zum aktuellen Standort berechnen
    double? distanceKm;
    if (_currentLocation != null) {
      const Distance distance = Distance();
      distanceKm = distance.as(
        LengthUnit.Kilometer,
        _currentLocation!,
        poi.location,
      );
    }

    final highlights = aiMeta?.highlights ?? const <String>[];
    final aiPhotoUrls = aiMeta?.photoUrls ?? const <String>[];
    final longDescription = aiMeta?.longDescription?.trim();
    final aiReason = aiMeta?.reason?.trim();
    final cardImageUrl =
        aiPhotoUrls.isNotEmpty ? aiPhotoUrls.first : poi.imageUrl;
    final showPhotoFallbackHint = cardImageUrl == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _navigateToPOI(poi),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  // POI-Bild oder Placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: cardImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: cardImageUrl,
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
                                poi.shortDescription.isNotEmpty
                                    ? poi.shortDescription
                                    : poi.categoryLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_chatWeatherCondition != null &&
                                _chatWeatherCondition !=
                                    WeatherCondition.unknown &&
                                _chatWeatherCondition !=
                                    WeatherCondition.mixed) ...[
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.5),
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
            if (showPhotoFallbackHint)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.chatNoPhotoFallbackHint,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (highlights.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: highlights.take(4).map((h) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (longDescription != null && longDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  longDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (aiReason != null && aiReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  aiReason,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToPOI(poi),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(context.l10n.mapDetails),
                  ),
                  TextButton.icon(
                    onPressed: () => _showOnMap(poi),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: Text(context.l10n.showOnMap),
                  ),
                  TextButton.icon(
                    onPressed: () => _addPoiToRoute(poi),
                    icon: const Icon(Icons.route_rounded, size: 16),
                    label: Text(context.l10n.poiAddToRoute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Icon fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r POI-Kategorie
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
    // POI zum State hinzufÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼gen (damit POI-Detail-Screen ihn findet)
    ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);

    // Enrichment starten falls kein Bild
    if (poi.imageUrl == null) {
      ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
    }

    // Navigieren
    context.push('/poi/${poi.id}');
  }

  void _showOnMap(POI poi) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    poiNotifier.addPOI(poi);
    poiNotifier.selectPOI(poi);
    ref.read(pendingMapCenterProvider.notifier).state = poi.location;
    context.go('/');
  }

  Future<void> _addPoiToRoute(POI poi) async {
    final tripNotifier = ref.read(tripStateProvider.notifier);
    final result = await tripNotifier.addStopWithAutoRoute(poi);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.poiAddedToRoute(poi.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/trip');
      return;
    }

    final fallbackError =
        result.message ?? context.l10n.chatPoisSearchErrorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fallbackError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll('\u00E4', 'ae')
        .replaceAll('\u00F6', 'oe')
        .replaceAll('\u00FC', 'ue')
        .replaceAll('\u00DF', 'ss')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsAnyToken(String text, List<String> tokens) {
    return tokens.any(text.contains);
  }

  bool _isRestaurantIntent(String query) {
    final normalized = _normalizeText(query);
    return _containsAnyToken(normalized, const [
      'restaurant',
      'essen',
      'food',
      'mittagessen',
      'abendessen',
      'fruehstueck',
      'fruhstueck',
      'dinner',
      'lunch',
      'cafe',
      'bar',
      'bistro',
      'pizza',
      'burger',
      'kueche',
      'kuchen',
    ]);
  }

  bool _isHotelIntent(String query) {
    final normalized = _normalizeText(query);
    return _containsAnyToken(normalized, const [
      'hotel',
      'uebernacht',
      'unterkunft',
      'hostel',
      'pension',
      'airbnb',
      'schlafen',
      'zimmer',
      'resort',
    ]);
  }

  bool _matchesRestaurantPoi(POI poi) {
    final normalizedPoiText = _normalizeText(
      '${poi.name} ${poi.categoryLabel} ${poi.shortDescription} ${poi.description ?? ''} ${poi.wikidataDescription ?? ''}',
    );
    return poi.categoryId == 'restaurant' ||
        _containsAnyToken(normalizedPoiText, const [
          'restaurant',
          'essen',
          'food',
          'cafe',
          'bar',
          'bistro',
          'pizza',
          'burger',
          'kueche',
        ]);
  }

  bool _matchesHotelPoi(POI poi) {
    final normalizedPoiText = _normalizeText(
      '${poi.name} ${poi.categoryLabel} ${poi.shortDescription} ${poi.description ?? ''} ${poi.wikidataDescription ?? ''}',
    );
    return poi.categoryId == 'hotel' ||
        _containsAnyToken(normalizedPoiText, const [
          'hotel',
          'hostel',
          'unterkunft',
          'uebernacht',
          'pension',
          'resort',
          'zimmer',
        ]);
  }

  bool _isRouteCreationIntent(String query) {
    final normalized = _normalizeText(query);
    return _containsAnyToken(normalized, const [
      'route bauen',
      'route erstellen',
      'route planen',
      'trip bauen',
      'trip erstellen',
      'trip planen',
      'roadtrip',
      'itinerary',
      'tour planen',
      'tagestrip',
    ]);
  }

  /// PrÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼ft ob die Anfrage standortbasiert ist
  bool _isLocationBasedQuery(String query) {
    final lowerQuery = _normalizeText(query);
    final locationKeywords = [
      'in meiner naehe',
      'um mich',
      'hier',
      'in der naehe',
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
    final lowerQuery = _normalizeText(query);

    // Kategorie-Mapping (v1.7.9: ungueltige IDs gefixt + erweitert)
    // Gueltige IDs: castle, nature, museum, viewpoint, lake, coast, park,
    //               city, activity, hotel, restaurant, unesco, church, monument, attraction
    final categoryMapping = <String, List<String>>{
      'sehenswuerd': ['museum', 'monument', 'castle', 'viewpoint', 'unesco'],
      'museum': ['museum'],
      'schloss': ['castle'],
      'schloesser': ['castle'],
      'burg': ['castle'],
      'kirche': ['church'],
      'natur': ['nature', 'park', 'lake', 'coast'],
      'park': ['park', 'nature'],
      'see': ['lake'],
      'restaurant': ['restaurant'],
      'essen': ['restaurant'],
      'hotel': ['hotel'],
      'uebernacht': ['hotel'],
      'aussicht': ['viewpoint'],
      'kultur': ['museum', 'monument', 'church', 'castle', 'unesco'],
      'strand': ['coast'],
      'kueste': ['coast'],
      'aktivitaet': ['activity'],
      'sport': ['activity'],
      'wandern': ['nature', 'viewpoint', 'park'],
      'familie': ['activity', 'park', 'museum'],
      'zoo': ['activity'],
      'freizeitpark': ['activity'],
      'therme': ['activity'],
      'stadt': ['city'],
      'indoor': [
        'museum',
        'church',
        'restaurant',
        'hotel',
        'castle',
        'activity'
      ],
      'outdoor': ['nature', 'park', 'lake', 'coast', 'viewpoint'],
      'regen': [
        'museum',
        'church',
        'restaurant',
        'hotel',
        'castle',
        'activity'
      ],
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
    if (_isLoading) return;

    final requestToken = _startRequest(ChatRequestKind.nearby);
    final l10n = context.l10n;
    final responseLanguage = Localizations.localeOf(context).languageCode;
    var loadingStarted = false;

    setState(() {
      _addTextMessage(content: query, isUser: true);
      _isLoading = true;
      loadingStarted = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      if (_currentLocation == null) {
        await _initializeLocation();

        if (_currentLocation == null) {
          final serviceEnabled = await LocationHelper.isServiceEnabled();
          if (!serviceEnabled) {
            final shouldOpen = await _showGpsDialog();
            if (shouldOpen) {
              await LocationHelper.openSettings();
            }
          }

          if (!mounted || !_isCurrentRequest(requestToken)) return;
          setState(() {
            _isLoading = false;
            _addTextMessage(
              content: '**${l10n.chatLocationNotAvailable}**\n\n'
                  '${l10n.chatLocationNotAvailableMessage}',
              isUser: false,
            );
          });
          _scrollToBottom();
          return;
        }
      }

      final currentLocation = _currentLocation!;
      debugPrint(
          '[AI-Chat] Suche POIs um ${currentLocation.latitude}, ${currentLocation.longitude} mit Radius ${_searchRadius}km');

      final categories = _getCategoriesFromQuery(query);
      final isRestaurantQuery = _isRestaurantIntent(query);
      final isHotelQuery = _isHotelIntent(query);
      final poiRepo = ref.read(poiRepositoryProvider);
      var pois = await poiRepo
          .loadPOIsInRadius(
            center: currentLocation,
            radiusKm: _searchRadius,
            categoryFilter: categories,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => <POI>[],
          );

      if (isRestaurantQuery || isHotelQuery) {
        List<POI> filterByIntent(List<POI> source) {
          if (isRestaurantQuery) {
            return source.where(_matchesRestaurantPoi).toList();
          }
          return source.where(_matchesHotelPoi).toList();
        }

        var intentFiltered = filterByIntent(pois);
        if (intentFiltered.isEmpty) {
          final fallbackPois = await poiRepo
              .loadPOIsInRadius(
                center: currentLocation,
                radiusKm: _searchRadius,
                categoryFilter: null,
              )
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () => <POI>[],
              );
          intentFiltered = filterByIntent(fallbackPois);
        }
        pois = intentFiltered;
      }

      if (!mounted) return;
      debugPrint('[AI-Chat] ${pois.length} POIs gefunden');

      const distanceCalculator = Distance();
      var sortedPOIs = List<POI>.from(pois);
      sortedPOIs.sort((a, b) {
        final distA = distanceCalculator.as(
            LengthUnit.Kilometer, currentLocation, a.location);
        final distB = distanceCalculator.as(
            LengthUnit.Kilometer, currentLocation, b.location);
        return distA.compareTo(distB);
      });

      final weatherState = ref.read(locationWeatherNotifierProvider);
      final chatWeatherCondition = weatherState.condition;
      if (chatWeatherCondition != WeatherCondition.unknown &&
          chatWeatherCondition != WeatherCondition.mixed) {
        sortedPOIs = WeatherPOIUtils.sortByWeatherRelevance(
          sortedPOIs,
          chatWeatherCondition,
        );
      }

      final aiMeta = <String, AiPoiMeta>{};
      String aiSummary = '';

      if (_backendAvailable && sortedPOIs.isNotEmpty) {
        try {
          final aiService = ref.read(aiServiceProvider);
          final tripState = ref.read(tripStateProvider);
          final candidates = sortedPOIs.take(40).toList();

          final request = AIPoiSuggestionRequest(
            mode: AIPoiSuggestionMode.chatNearby,
            language: responseLanguage,
            userContext: AIPoiSuggestionUserContext(
              lat: currentLocation.latitude,
              lng: currentLocation.longitude,
              locationName: _currentLocationName,
              weatherCondition: chatWeatherCondition,
            ),
            tripContext: AIPoiSuggestionTripContext(
              routeStart: tripState.route?.startAddress,
              routeEnd: tripState.route?.endAddress,
              stops: tripState.stops
                  .take(20)
                  .map(
                    (stop) => AIPoiSuggestionStop(
                      id: stop.id,
                      name: stop.name,
                      categoryId: stop.categoryId,
                    ),
                  )
                  .toList(),
            ),
            constraints: AIPoiSuggestionConstraints(
              maxSuggestions: 8,
              allowSwap: false,
            ),
            candidates:
                candidates.map(AIPoiSuggestionCandidate.fromPOI).toList(),
          );

          final structured = await aiService
              .getPoiSuggestionsStructured(
                request: request,
              )
              .timeout(const Duration(seconds: 18));

          aiSummary = structured.summary.trim();
          final byId = {for (final poi in sortedPOIs) poi.id: poi};
          final prioritized = <POI>[];
          for (final suggestion in structured.suggestions.take(8)) {
            final poi = byId[suggestion.poiId];
            if (poi == null) continue;
            prioritized.add(poi);
            aiMeta[poi.id] = AiPoiMeta(
              reason: suggestion.reason,
              highlights: suggestion.highlights,
              longDescription: suggestion.longDescription,
              photoUrls: const [],
            );
          }

          if (prioritized.isNotEmpty) {
            final prioritizedIds = prioritized.map((p) => p.id).toSet();
            sortedPOIs = [
              ...prioritized,
              ...sortedPOIs.where((poi) => !prioritizedIds.contains(poi.id)),
            ];
          }
        } catch (e) {
          debugPrint('[AI-Chat] Strukturierte Suggestions fehlgeschlagen: $e');
        }
      }

      if (aiMeta.isNotEmpty) {
        final aiTargetIds = aiMeta.keys.toSet();
        final topAIPois = sortedPOIs
            .where((poi) => aiTargetIds.contains(poi.id))
            .take(8)
            .toList();

        if (topAIPois.isNotEmpty) {
          try {
            final enrichmentService = ref.read(poiEnrichmentServiceProvider);
            final enrichedMap =
                await enrichmentService.enrichPOIsBatch(topAIPois).timeout(
                      const Duration(seconds: 12),
                      onTimeout: () => <String, POI>{},
                    );
            sortedPOIs =
                sortedPOIs.map((poi) => enrichedMap[poi.id] ?? poi).toList();

            final socialRepo = ref.read(poiSocialRepositoryProvider);
            final photoResults = await Future.wait(
              topAIPois.map((poi) async {
                final effective = enrichedMap[poi.id] ?? poi;
                final urls = <String>{};
                if (effective.imageUrl != null &&
                    effective.imageUrl!.isNotEmpty) {
                  urls.add(effective.imageUrl!);
                }
                try {
                  final photos = await socialRepo
                      .loadPhotos(effective.id, limit: 3)
                      .timeout(
                        const Duration(seconds: 10),
                        onTimeout: () => [],
                      );
                  for (final photo in photos) {
                    final url = getStorageUrl(photo.storagePath);
                    if (url.isNotEmpty) {
                      urls.add(url);
                    }
                  }
                } catch (e) {
                  debugPrint(
                      '[AI-Chat] Social-Fotos fuer ${effective.id} fehlgeschlagen: $e');
                }
                return MapEntry(effective.id, urls.toList());
              }),
            );

            final byId = {for (final poi in sortedPOIs) poi.id: poi};
            for (final entry in photoResults) {
              final meta = aiMeta[entry.key];
              if (meta == null) continue;
              var nextMeta = meta.copyWith(photoUrls: entry.value);
              if ((nextMeta.longDescription ?? '').trim().isEmpty) {
                final poi = byId[entry.key];
                if (poi != null) {
                  nextMeta = nextMeta.copyWith(
                    longDescription: poi.description ??
                        poi.wikidataDescription ??
                        poi.shortDescription,
                  );
                }
              }
              aiMeta[entry.key] = nextMeta;
            }
          } catch (e) {
            debugPrint('[AI-Chat] Media-Enrichment fehlgeschlagen: $e');
          }
        }
      }

      final radiusStr = _searchRadius.toInt().toString();
      String headerText;
      if (categories != null && categories.isNotEmpty) {
        headerText =
            '**${l10n.chatPoisInRadius(sortedPOIs.length, radiusStr)}** (${categories.join(', ')}):';
      } else {
        headerText =
            '**${l10n.chatPoisInRadius(sortedPOIs.length, radiusStr)}**:';
      }
      if (aiSummary.isNotEmpty) {
        headerText = '$headerText\n$aiSummary';
      }

      if (!mounted || !_isCurrentRequest(requestToken)) return;
      setState(() {
        _isLoading = false;
        _addPoiListMessage(
          content: headerText,
          pois: sortedPOIs,
          aiMeta: aiMeta,
        );
        _maybeAddCopilotCard(
          sourceQuery: query,
          suggestedPOIs: sortedPOIs.take(8).toList(),
        );
      });
      _scrollToBottom();

      final messageIndex = _messages.length - 1;
      final poisToEnrich = sortedPOIs
          .where((p) => p.imageUrl == null && !p.isEnriched)
          .take(10)
          .toList();

      if (poisToEnrich.isNotEmpty) {
        debugPrint(
            '[AI-Chat] Starte Hintergrund-Enrichment fuer ${poisToEnrich.length} POIs');
        final enrichmentService = ref.read(poiEnrichmentServiceProvider);
        final enrichedMap =
            await enrichmentService.enrichPOIsBatch(poisToEnrich).timeout(
                  const Duration(seconds: 12),
                  onTimeout: () => <String, POI>{},
                );

        if (mounted &&
            _isCurrentRequest(requestToken) &&
            messageIndex < _messages.length) {
          final updatedPOIs =
              sortedPOIs.map((poi) => enrichedMap[poi.id] ?? poi).toList();
          setState(() {
            final currentMessage = _messages[messageIndex];
            if (currentMessage is! PoiListMessage) {
              return;
            }
            final existingMeta = Map<String, AiPoiMeta>.from(
              currentMessage.aiMeta,
            );

            for (final poi in updatedPOIs) {
              final meta = existingMeta[poi.id];
              if (meta == null) continue;
              final currentPhotos = meta.photoUrls
                  .map((url) => url.toString().trim())
                  .where((url) => url.isNotEmpty)
                  .toList();
              var nextMeta = meta;
              if (currentPhotos.isEmpty &&
                  poi.imageUrl != null &&
                  poi.imageUrl!.isNotEmpty) {
                nextMeta = nextMeta.copyWith(photoUrls: [poi.imageUrl!]);
              }
              if ((nextMeta.longDescription ?? '').trim().isEmpty) {
                nextMeta = nextMeta.copyWith(
                  longDescription: poi.description ??
                      poi.wikidataDescription ??
                      poi.shortDescription,
                );
              }
              existingMeta[poi.id] = nextMeta;
            }

            _messages[messageIndex] = currentMessage.copyWith(
              pois: updatedPOIs,
              aiMeta: existingMeta,
            );
          });
          debugPrint('[AI-Chat] Hintergrund-Enrichment abgeschlossen');
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('[AI-Chat] POI-Suche Timeout: $e');

      if (mounted && _isCurrentRequest(requestToken)) {
        setState(() {
          _isLoading = false;
          _addTextMessage(
            content:
                '**${l10n.chatPoisSearchError}**\n\nDie Anfrage hat zu lange gedauert. Bitte versuche es erneut.',
            isUser: false,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[AI-Chat] POI-Suche Fehler: $e');

      if (mounted && _isCurrentRequest(requestToken)) {
        setState(() {
          _isLoading = false;
          _addTextMessage(
            content:
                '**${l10n.chatPoisSearchError}**\n\n${l10n.chatPoisSearchErrorMessage}',
            isUser: false,
          );
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted &&
          _isCurrentRequest(requestToken) &&
          loadingStarted &&
          _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _finishRequest(requestToken);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isLoading) return;

    final requestToken = _startRequest(ChatRequestKind.chat);
    final userMessage = text.trim();
    final normalizedMessage = _normalizeText(userMessage);
    var loadingStarted = false;

    try {
      if (_isRouteCreationIntent(normalizedMessage)) {
        setState(() {
          _addTextMessage(content: userMessage, isUser: true);
          _addTextMessage(
            content:
                'Ich oeffne den Routen-Generator. Gib dort Ziel und Start ein, dann uebernehme ich die Route direkt in deine Planung.',
            isUser: false,
          );
        });
        _messageController.clear();
        _scrollToBottom();
        _showTripGeneratorDialog();
        return;
      }

      if (_isRestaurantIntent(normalizedMessage) ||
          _isHotelIntent(normalizedMessage)) {
        final localCategoryQuery = _isLocationBasedQuery(userMessage)
            ? userMessage
            : '$userMessage in meiner Naehe';
        await _handleLocationBasedQuery(localCategoryQuery);
        return;
      }

      if (_isLocationBasedQuery(userMessage)) {
        await _handleLocationBasedQuery(userMessage);
        return;
      }

      setState(() {
        _addTextMessage(content: userMessage, isUser: true);
        _isLoading = true;
        loadingStarted = true;
      });
      _rememberTripMessage(content: userMessage, isUser: true);

      _messageController.clear();
      _scrollToBottom();

      if (!_backendAvailable) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted || !_isCurrentRequest(requestToken)) return;

        setState(() {
          _isLoading = false;
          _addTextMessage(
            content: _generateSmartDemoResponse(userMessage),
            isUser: false,
          );
        });
        _scrollToBottom();
        return;
      }

      final aiService = ref.read(aiServiceProvider);
      debugPrint('[AI-Chat] Sende Anfrage an Backend...');

      final tripScopedHistory = List<ChatMessage>.from(
        _tripScopedHistory[_activeTripKey()] ?? const <ChatMessage>[],
      );
      final history = tripScopedHistory.isNotEmpty
          ? tripScopedHistory
          : _messages
              .where((m) => m.content.trim().isNotEmpty)
              .map((m) => ChatMessage(
                    content: m.content,
                    isUser: m.isUser,
                  ))
              .toList();

      final tripState = ref.read(tripStateProvider);
      final tripContext = TripContext(
        route: tripState.route,
        stops: tripState.stops,
        userLatitude: _currentLocation?.latitude,
        userLongitude: _currentLocation?.longitude,
        userLocationName: _currentLocationName,
      );

      final response = await aiService
          .chat(
            message: userMessage,
            context: tripContext,
            history: history.take(10).toList(),
          )
          .timeout(const Duration(seconds: 35));

      if (!mounted || !_isCurrentRequest(requestToken)) return;

      final responseText =
          response.isNotEmpty ? response : context.l10n.chatNoResponseGenerated;

      setState(() {
        _isLoading = false;
        _addTextMessage(
          content: responseText,
          isUser: false,
        );
        _maybeAddCopilotCard(sourceQuery: userMessage);
      });
      _rememberTripMessage(
        content: responseText,
        isUser: false,
      );
      _scrollToBottom();
    } on TimeoutException {
      if (!mounted || !_isCurrentRequest(requestToken)) return;
      const fallbackMessage =
          'Die Anfrage dauert zu lange. Bitte versuche es erneut.';

      setState(() {
        _backendAvailable = false;
        _isLoading = false;
        _addTextMessage(content: fallbackMessage, isUser: false);
      });
      _rememberTripMessage(content: fallbackMessage, isUser: false);
      _scrollToBottom();
    } catch (e) {
      debugPrint('[AI-Chat] Fehler: $e');

      if (!mounted || !_isCurrentRequest(requestToken)) return;
      final fallbackMessage = e is AIException
          ? e.message
          : _generateSmartDemoResponse(userMessage);

      setState(() {
        if (e is! AIException || !e.isRetryable) {
          _backendAvailable = false;
        }
        _isLoading = false;
        _addTextMessage(content: fallbackMessage, isUser: false);
      });
      _rememberTripMessage(content: fallbackMessage, isUser: false);
      _scrollToBottom();
    } finally {
      if (mounted &&
          _isCurrentRequest(requestToken) &&
          loadingStarted &&
          _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _finishRequest(requestToken);
    }
  }

  /// Intelligente Demo-Antworten basierend auf Schluesselwoertern
  String _generateSmartDemoResponse(String query) {
    final lowerQuery = _normalizeText(query);

    if (lowerQuery.contains('sehenswuerd') ||
        lowerQuery.contains('sightseeing') ||
        lowerQuery.contains('besichtigen') ||
        lowerQuery.contains('highlight')) {
      final tripState = ref.read(tripStateProvider);
      if (tripState.hasRoute && tripState.stops.isNotEmpty) {
        final stopList = tripState.stops
            .take(5)
            .map((s) => '- ${s.name} (${s.categoryLabel})')
            .join('\n');
        return '**Sehenswuerdigkeiten auf deiner Route:**\n\n'
            '$stopList\n\n'
            'Tippe auf einen Stop im Trip-Screen fuer Details.';
      }
      return '**Top Sehenswuerdigkeiten:**\n\n'
          '- Schloss Neuschwanstein\n'
          '- Zugspitze\n'
          '- Partnachklamm\n'
          '- Marienplatz Muenchen\n\n'
          'Erstelle eine Route, um personalisierte Empfehlungen zu erhalten.';
    }

    if (lowerQuery.contains('natur') ||
        lowerQuery.contains('park') ||
        lowerQuery.contains('wald') ||
        lowerQuery.contains('see')) {
      return '**Naturhighlights:**\n\n'
          '- Koenigssee\n'
          '- Nationalpark Berchtesgaden\n'
          '- Partnachklamm\n'
          '- Englischer Garten\n\n'
          'Waehle "AI-Trip generieren" mit Interesse "Natur" fuer eine passende Route.';
    }

    if (_isRestaurantIntent(lowerQuery)) {
      return '**Restaurant-Empfehlungen:**\n\n'
          '- Hofbraeuhaus Muenchen\n'
          '- Augustiner Braeustuben\n'
          '- Prinz Myshkin\n\n'
          'Tipp: Frag mich nach "Restaurants in meiner Naehe" fuer konkrete POIs.';
    }

    if (_isHotelIntent(lowerQuery)) {
      return '**Hotel- und Unterkunftstipps:**\n\n'
          '- Frag mich nach "Hotels in meiner Naehe"\n'
          '- Oder nenne eine Stadt, z. B. "Hotels in Berlin"\n'
          '- Ich kann Unterkuenfte entlang deiner Route anzeigen\n\n'
          'Sobald eine Route aktiv ist, priorisiere ich Hotels entlang des Weges.';
    }

    if (lowerQuery.contains('wetter') ||
        lowerQuery.contains('regen') ||
        lowerQuery.contains('sonne')) {
      return '**Wetter-Info:**\n\n'
          'Aktuelle Wetterdaten siehst du auf dem Map-Screen und bei wetterkritischen POIs.\n\n'
          'Tipp: Bei Regen empfehle ich Museen und Indoor-Attraktionen.';
    }

    if (lowerQuery.contains('route') ||
        lowerQuery.contains('fahrt') ||
        lowerQuery.contains('weg')) {
      final tripState = ref.read(tripStateProvider);
      if (tripState.hasRoute) {
        return '**Deine aktuelle Route:**\n\n'
            'Start: ${tripState.route!.startAddress}\n'
            'Ziel: ${tripState.route!.endAddress}\n'
            'Distanz: ${tripState.route!.distanceKm.toStringAsFixed(0)} km\n'
            'Fahrzeit: ${(tripState.route!.durationMinutes / 60).toStringAsFixed(1)} h\n'
            'Stops: ${tripState.stops.length}\n\n'
            'Gehe zum Trip-Screen fuer Details.';
      }
      return '**Route erstellen:**\n\n'
          '1. Gehe zum Karten-Screen\n'
          '2. Setze Start- und Zielpunkt\n'
          '3. Oder nutze "AI-Trip generieren"\n\n'
          'Dann kann ich dir Empfehlungen entlang der Route geben.';
    }

    if (lowerQuery.contains('hilfe') ||
        lowerQuery.contains('help') ||
        lowerQuery.contains('kannst du') ||
        lowerQuery.contains('was kann')) {
      return '**Was ich kann:**\n\n'
          '- Routen-Infos geben\n'
          '- Sehenswuerdigkeiten empfehlen\n'
          '- Naturhighlights zeigen\n'
          '- Restaurants und Hotels finden\n'
          '- AI-Trips generieren\n\n'
          'Frag mich einfach oder waehle einen Vorschlag unten.';
    }

    final cities = <String, String>{
      'muenchen': 'Muenchen',
      'berlin': 'Berlin',
      'hamburg': 'Hamburg',
      'koeln': 'Koeln',
      'prag': 'Prag',
      'wien': 'Wien',
      'salzburg': 'Salzburg',
    };
    for (final entry in cities.entries) {
      if (lowerQuery.contains(entry.key)) {
        final city = entry.value;
        return '**$city erkunden:**\n\n'
            'Nutze "AI-Trip generieren" und gib "$city" als Ziel ein.\n\n'
            'Dort kannst du Tage und Interessen waehlen und bekommst eine optimierte Route.';
      }
    }

    return '**Interessante Frage!**\n\n'
        'Mit aktiver Backend-Verbindung kann ich hier detailliert antworten.\n\n'
        '**Probiere diese Funktionen:**\n'
        '- AI-Trip generieren\n'
        '- Route auf der Karte erstellen\n'
        '- POIs in der Naehe suchen\n'
        '- Restaurants oder Hotels anfragen';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
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
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatClearConfirm),
        content: Text(l10n.chatClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _tripScopedHistory.clear();
                _addTextMessage(content: l10n.chatWelcome, isUser: false);
              });
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSuggestionTap(String suggestion) async {
    if (_isLoading) return;

    final normalized = _normalizeText(suggestion);

    if (_containsAnyToken(
        normalized, const ['hotel', 'unterkunft', 'uebernacht'])) {
      await _handleLocationBasedQuery('Zeig mir Hotels in meiner Naehe');
      return;
    }

    if (normalized.contains(_normalizeText(context.l10n.chatPoisNearMe))) {
      await _handleLocationBasedQuery('Zeig mir POIs in meiner Naehe');
    } else if (normalized
        .contains(_normalizeText(context.l10n.chatAttractions))) {
      await _handleLocationBasedQuery(
        'Zeig mir Sehenswuerdigkeiten in meiner Naehe',
      );
    } else if (normalized
        .contains(_normalizeText(context.l10n.chatNatureParks))) {
      await _handleLocationBasedQuery(
          'Zeig mir Natur und Parks in meiner Naehe');
    } else if (normalized
        .contains(_normalizeText(context.l10n.chatRestaurants))) {
      await _handleLocationBasedQuery('Zeig mir Restaurants in meiner Naehe');
    } else if (normalized
        .contains(_normalizeText(context.l10n.chatIndoorTips))) {
      await _handleLocationBasedQuery(
        'Zeig mir Indoor-Tipps bei Regen in meiner Naehe',
      );
    } else if (normalized
        .contains(_normalizeText(context.l10n.chatOutdoorHighlights))) {
      await _handleLocationBasedQuery(
        'Zeig mir Outdoor-Highlights in meiner Naehe',
      );
    } else {
      await _sendMessage(suggestion);
    }
  }

  void _showTripGeneratorDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
          title: Text('AI ${l10n.chatGenerateAiTrip}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ziel (optional fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r Random Route)
                TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    labelText: l10n.chatDestinationOptional,
                    hintText: l10n.chatEmptyRandomRoute,
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),

                // Startpunkt (optional - GPS-Fallback)
                TextField(
                  controller: startController,
                  decoration: InputDecoration(
                    labelText: l10n.chatStartOptional,
                    hintText: l10n.chatEmptyUseGps,
                    prefixIcon: const Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 16),

                // Tage
                Text(
                  l10n.chatNumberOfDays,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${days.round()} ${days.round() == 1 ? l10n.tripConfigDay : l10n.tripConfigDays}',
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
                  label: '${days.round()} ${l10n.tripConfigDays}',
                  onChanged: (value) {
                    setDialogState(() {
                      days = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Interessen
                Text(
                  l10n.chatInterests,
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
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final destination = destinationController.text.trim();
                final startText = startController.text.trim();
                final interestsList = selectedInterests.toList();
                final daysInt = days.round();

                // Dialog schlieÃƒÂƒÃ†Â’ÃƒÂ…Ã‚Â¸en
                Navigator.pop(context);

                // HYBRID-LOGIK:
                // Wenn Ziel angegeben ÃƒÂƒÃ‚Â¢ÃƒÂ¢Ã¢Â‚Â¬Ã‚Â ÃƒÂ¢Ã¢Â‚Â¬Ã¢Â„Â¢ AI-Text-Plan (wie bisher)
                // Wenn Ziel leer ÃƒÂƒÃ‚Â¢ÃƒÂ¢Ã¢Â‚Â¬Ã‚Â ÃƒÂ¢Ã¢Â‚Â¬Ã¢Â„Â¢ Random Route um Startpunkt/GPS

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
                    if (!mounted) return;
                    setState(() {
                      _addTextMessage(
                        content: 'Konnte keinen Standort ermitteln.\n\n'
                            'Bitte gib einen Startpunkt ein oder aktiviere GPS.',
                        isUser: false,
                      );
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
              child: Text(l10n.generate),
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
    if (_isLoading) return;
    final requestToken = _startRequest(ChatRequestKind.tripPlan);

    setState(() {
      _addTextMessage(
        content:
            'Generiere einen $days-Tage Trip nach $destination\n${interests.isNotEmpty ? "Interessen: ${interests.join(', ')}" : ""}',
        isUser: true,
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      if (!_backendAvailable) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_isCurrentRequest(requestToken)) return;

        setState(() {
          _isLoading = false;
          _addTextMessage(
            content: _generateDemoTripPlan(destination, days, interests),
            isUser: false,
          );
        });
        _scrollToBottom();
        return;
      }

      final aiService = ref.read(aiServiceProvider);
      final plan = await aiService.generateTripPlan(
        destination: destination,
        days: days,
        interests: interests,
        startLocation: startLocation,
      );

      if (!mounted || !_isCurrentRequest(requestToken)) return;

      final planText = StringBuffer();
      planText.writeln('${plan.title}\n');
      if (plan.description != null && plan.description!.isNotEmpty) {
        planText.writeln('${plan.description}\n');
      }

      for (final day in plan.days) {
        planText.writeln('**${day.title}**');
        if (day.description != null) {
          planText.writeln(day.description);
        }
        for (final stop in day.stops) {
          planText.writeln(
              '- ${stop.name} ${stop.duration != null ? "(${stop.duration})" : ""}');
          if (stop.description != null) {
            planText.writeln('  ${stop.description}');
          }
        }
        planText.writeln();
      }

      setState(() {
        _isLoading = false;
        _addTextMessage(
          content: planText.toString(),
          isUser: false,
        );
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('[Trip Generator] Fehler: $e');
      if (!mounted || !_isCurrentRequest(requestToken)) return;

      setState(() {
        _backendAvailable = false;
        _isLoading = false;
        _addTextMessage(
          content: _generateDemoTripPlan(destination, days, interests),
          isUser: false,
        );
      });
      _scrollToBottom();
    } finally {
      _finishRequest(requestToken);
    }
  }

  /// GPS-Standort oder Geocoding fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r manuelle Eingabe abrufen
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
            address: result.displayName
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
    if (!mounted) return null;

    // Reverse Geocoding fÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼r Adresse
    String address = context.l10n.chatMyLocation;
    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final result = await geocodingRepo.reverseGeocode(position);
      if (result != null) {
        address = result.shortName ?? result.displayName;
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

    // Wenn keine Interessen gewÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¤hlt, alle Kategorien verwenden (auÃƒÂƒÃ†Â’ÃƒÂ…Ã‚Â¸er Hotel)
    if (categoryIds.isEmpty) {
      return POICategory.values.where((c) => c != POICategory.hotel).toList();
    }

    return POICategory.values.where((c) => categoryIds.contains(c.id)).toList();
  }

  /// Random Trip generieren und an Trip-Screen ÃƒÂƒÃ†Â’ÃƒÂ‚Ã‚Â¼bergeben
  Future<void> _generateRandomTripFromLocation({
    required double lat,
    required double lng,
    required String address,
    required List<String> interests,
    required int days,
  }) async {
    if (_isLoading) return;
    final requestToken = _startRequest(ChatRequestKind.randomTrip);

    setState(() {
      _addTextMessage(
        content: 'Generiere zufaellige Route um "$address"\n'
            '${interests.isNotEmpty ? "Interessen: ${interests.join(', ')}" : "Alle Kategorien"}',
        isUser: true,
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final categories = _mapInterestsToCategories(interests);
      final tripGenerator = ref.read(tripGeneratorRepositoryProvider);
      final result = await tripGenerator.generateDayTrip(
        startLocation: LatLng(lat, lng),
        startAddress: address,
        radiusKm: days == 1 ? 100 : (days * 80).clamp(100, 300).toDouble(),
        categories: categories,
        poiCount: (days * 3).clamp(4, 9),
      );

      if (!mounted || !_isCurrentRequest(requestToken)) return;

      setState(() {
        _isLoading = false;
        _addTextMessage(
          content: 'Route generiert!\n\n'
              '${result.trip.name}\n'
              '${result.trip.route.distanceKm.toStringAsFixed(0)} km\n'
              '${(result.trip.route.durationMinutes / 60).toStringAsFixed(1)}h Fahrzeit\n'
              '${result.selectedPOIs.length} Stops\n\n'
              'Oeffne Trip-Screen...',
          isUser: false,
        );
      });
      _scrollToBottom();

      ref.read(routeSessionProvider.notifier).stopRoute();
      ref.read(pOIStateNotifierProvider.notifier).clearPOIs();

      final tripState = ref.read(tripStateProvider.notifier);
      tripState.setRoute(result.trip.route);
      tripState.setStops(result.selectedPOIs);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _isCurrentRequest(requestToken)) {
        context.go('/trip');
      }
    } catch (e) {
      debugPrint('[AI-Trip] Random Trip Fehler: $e');
      if (!mounted || !_isCurrentRequest(requestToken)) return;

      setState(() {
        _isLoading = false;
        _addTextMessage(
          content: 'Fehler beim Generieren der Route:\n$e\n\n'
              'Bitte versuche es erneut oder gib ein konkretes Ziel ein.',
          isUser: false,
        );
      });
      _scrollToBottom();
    } finally {
      _finishRequest(requestToken);
    }
  }

  String _generateDemoTripPlan(
      String destination, int days, List<String> interests) {
    final interestsText = interests.isNotEmpty
        ? 'Basierend auf deinen Interessen (${interests.join(', ')}):\n\n'
        : '';

    return '**$days Tage in $destination**\n\n'
        '$interestsText'
        '**Tag 1: Ankunft und Stadterkundung**\n'
        '- Hauptbahnhof (1h) - Ankunft und Check-in\n'
        '- Altstadt (2h) - Historisches Zentrum erkunden\n'
        '- Stadtmuseum (1.5h) - Geschichte kennenlernen\n\n'
        '**Tag 2: Kultur und Sehenswuerdigkeiten**\n'
        '- Schloss oder Burg (2h) - Wahrzeichen der Stadt\n'
        '- Kunstgalerie (1.5h) - Lokale Kunstszene\n'
        '- Lokales Restaurant (1h) - Traditionelle Kueche\n\n'
        '${days > 2 ? "**Tag 3: Natur und Entspannung**\n- Park oder Garten (2h) - Gruene Oase\n- Aussichtspunkt (1h) - Panoramablick\n- Cafe (1h) - Kaffee und Kuchen\n\n" : ""}'
        '_Dies ist ein Demo-Plan. Mit Backend-Verbindung erhaeltst du personalisierte Empfehlungen._\n\n'
        '**Tipp:** Nutze "AI-Trip generieren" ohne Ziel fuer eine echte Route mit POIs!';
  }
}
