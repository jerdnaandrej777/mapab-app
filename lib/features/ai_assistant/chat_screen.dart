import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/trip_generator_repo.dart';
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

  // Demo-Nachrichten
  final List<Map<String, dynamic>> _messages = [
    {
      'content':
          'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?',
      'isUser': false,
    },
  ];

  final List<String> _suggestions = [
    '🤖 AI-Trip generieren',
    'Welche Sehenswürdigkeiten sind auf meiner Route?',
    'Zeige mir Naturhighlights',
    'Was ist das beste Restaurant unterwegs?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // AI-Status Banner
          _buildStatusBanner(),

          // Chat-Nachrichten
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
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
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    // Prüfe echten API-Status
    final aiService = ref.watch(aiServiceProvider);
    final isConfigured = aiService.isConfigured;

    if (isConfigured) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo-Modus: OpenAI API-Key nicht konfiguriert',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _showApiKeyDialog,
            child: const Text('Einrichten'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI-Reiseassistent',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Frag mich alles über deine Reise!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  fillColor: AppTheme.backgroundColor,
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
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
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

    setState(() {
      _messages.add({
        'content': text.trim(),
        'isUser': true,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);

      // Prüfe ob konfiguriert
      if (!aiService.isConfigured) {
        // Fallback auf Demo-Response wenn nicht konfiguriert
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'content': _generateDemoResponse(text),
            'isUser': false,
          });
        });
        _scrollToBottom();
        return;
      }

      // Echte API-Anfrage
      print('[Chat] Sende Anfrage an OpenAI...');
      final response = await aiService.chat(
        message: text,
        context: TripContext(
          route: null,
          stops: [],
        ),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add({
          'content': response,
          'isUser': false,
        });
      });
      _scrollToBottom();
    } catch (e) {
      print('[Chat] Fehler: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add({
          'content':
              'Entschuldigung, es gab einen Fehler bei der Anfrage. Bitte versuche es später erneut.\n\nFehler: $e',
          'isUser': false,
        });
      });
      _scrollToBottom();
    }
  }

  String _generateDemoResponse(String query) {
    // Demo-Antworten
    if (query.toLowerCase().contains('prag')) {
      return 'Für einen 3-Tage-Trip nach Prag empfehle ich:\n\n'
          '**Tag 1:** Prager Burg, Karlsbrücke, Altstädter Ring\n\n'
          '**Tag 2:** Vyšehrad, Nationalmuseum, Wenzelsplatz\n\n'
          '**Tag 3:** Kutná Hora (Tagesausflug), Sedlec-Beinhaus\n\n'
          'Soll ich diese Stops zu deiner Route hinzufügen?';
    }

    if (query.toLowerCase().contains('sehenswürd')) {
      return 'Auf deiner aktuellen Route findest du:\n\n'
          '🏰 **Schloss Neuschwanstein** - Must-See, 12 km Umweg\n'
          '🏔️ **Zugspitze** - Deutschlands höchster Berg\n'
          '🌲 **Partnachklamm** - Beeindruckende Klamm\n\n'
          'Möchtest du Details zu einem dieser Orte?';
    }

    if (query.toLowerCase().contains('restaurant')) {
      return 'Hier sind meine Restaurant-Empfehlungen entlang deiner Route:\n\n'
          '🍽️ **Gasthof Stern** in Garmisch - Bayerische Küche (4.5★)\n'
          '🍽️ **Alpenhof** bei Füssen - Alpenküche (4.3★)\n\n'
          'Ich kann auch nach vegetarischen oder veganen Optionen suchen.';
    }

    return 'Das ist eine interessante Frage! Im vollständigen Modus mit OpenAI-Integration könnte ich dir hier eine detaillierte Antwort geben.\n\n'
        'Um die AI-Features zu aktivieren, richte bitte deinen OpenAI API-Key in den Einstellungen ein.';
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

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenAI API-Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Für die vollständige AI-Integration benötigst du einen OpenAI API-Key.',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'API-Key',
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: API-Key speichern
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _handleSuggestionTap(String suggestion) {
    if (suggestion == '🤖 AI-Trip generieren') {
      _showTripGeneratorDialog();
    } else {
      _sendMessage(suggestion);
    }
  }

  void _showTripGeneratorDialog() {
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
                const Text(
                  'Anzahl Tage',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${days.round()} ${days.round() == 1 ? "Tag" : "Tage"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
                const Text(
                  'Interessen:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
            ElevatedButton(
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
      final aiService = ref.read(aiServiceProvider);

      if (!aiService.isConfigured) {
        // Demo-Response
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'content': _generateDemoTripPlan(destination, days),
            'isUser': false,
          });
        });
        _scrollToBottom();
        return;
      }

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
      if (plan.description != null) {
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
      print('[Trip Generator] Fehler: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add({
          'content':
              'Entschuldigung, es gab einen Fehler beim Generieren des Trips.\n\nFehler: $e',
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
        print('[AI-Trip] Geocoding Fehler: $e');
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
        print('[AI-Trip] Reverse Geocoding Fehler: $e');
      }

      return (lat: position.latitude, lng: position.longitude, address: address);
    } catch (e) {
      print('[AI-Trip] GPS Fehler: $e');
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
      print('[AI-Trip] Random Trip Fehler: $e');

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

  String _generateDemoTripPlan(String destination, int days) {
    return '🗺️ $days Tage in $destination\n\n'
        '**Tag 1: Ankunft & Stadterkund**ung\n'
        '• Hauptbahnhof (1h) - Ankunft und Check-in\n'
        '• Altstadt (2h) - Historisches Zentrum erkunden\n'
        '• Stadtmuseum (1.5h) - Geschichte kennenlernen\n\n'
        '**Tag 2: Kultur & Sehenswürdigkeiten**\n'
        '• Schloss/Burg (2h) - Wahrzeichen der Stadt\n'
        '• Kunstgalerie (1.5h) - Lokale Kunstszene\n'
        '• Lokales Restaurant (1h) - Traditionelle Küche\n\n'
        '${days > 2 ? "**Tag 3: Natur & Entspannung**\n• Park/Garten (2h) - Grüne Oase\n• Aussichtspunkt (1h) - Panoramablick\n• Café (1h) - Kaffee und Kuchen\n\n" : ""}'
        '💡 Dies ist ein Demo-Plan. Mit OpenAI-Integration erhältst du personalisierte Empfehlungen!';
  }
}
