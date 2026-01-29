import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/categories.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/trip_generator_repo.dart';
import '../../features/map/providers/route_session_provider.dart';
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

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _backendAvailable = true;

  // Chat-Nachrichten mit History für Backend
  final List<Map<String, dynamic>> _messages = [
    {
      'content':
          'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?',
      'isUser': false,
    },
  ];

  final List<String> _suggestions = [
    '🤖 AI-Trip generieren',
    '🗺️ Sehenswürdigkeiten auf Route',
    '🌲 Naturhighlights zeigen',
    '🍽️ Restaurants empfehlen',
  ];

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
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
      color: Colors.orange.withOpacity(0.15),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
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
              color: colorScheme.shadow.withOpacity(0.1),
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    setState(() {
      _messages.add({
        'content': userMessage,
        'isUser': true,
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

      // Trip-Kontext abrufen
      final tripState = ref.read(tripStateProvider);
      final context = TripContext(
        route: tripState.route,
        stops: tripState.stops,
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
      case '🤖 AI-Trip generieren':
        _showTripGeneratorDialog();
        break;
      case '🗺️ Sehenswürdigkeiten auf Route':
        _handleSehenswuerdigkeitenRequest();
        break;
      case '🌲 Naturhighlights zeigen':
        _handleNaturhighlightsRequest();
        break;
      case '🍽️ Restaurants empfehlen':
        _handleRestaurantRequest();
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
    );
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
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bitte aktiviere die Ortungsdienste')),
          );
        }
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Standort-Berechtigung verweigert')),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Standort-Berechtigung dauerhaft verweigert. '
                      'Bitte in Einstellungen aktivieren.'),
            ),
          );
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse Geocoding für Adresse
      String address = 'Mein Standort';
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.reverseGeocode(
          LatLng(position.latitude, position.longitude),
        );
        if (result != null) {
          address = result.shortName ?? result.displayName ?? address;
        }
      } catch (e) {
        debugPrint('[AI-Trip] Reverse Geocoding Fehler: $e');
      }

      return (lat: position.latitude, lng: position.longitude, address: address);
    } catch (e) {
      debugPrint('[AI-Trip] GPS Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS-Fehler: $e')),
        );
      }
      return null;
    }
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
