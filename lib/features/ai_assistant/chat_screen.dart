import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/trip.dart';
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
    'Plane einen 3-Tage-Trip nach Prag',
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
              onSelected: _sendMessage,
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
}
