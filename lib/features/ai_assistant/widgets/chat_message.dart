import 'package:flutter/material.dart';

/// Chat-Nachricht Bubble - Dark-Mode kompatibel
class ChatMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isLoading;

  const ChatMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? _buildLoadingIndicator(colorScheme)
                  : _buildContent(context, colorScheme),
            ),
          ),

          // User Avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    // Erweiteres Markdown-Parsing für fett, kursiv und Zeilenumbrüche
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return Text.rich(
      _parseMarkdown(content, textColor),
      style: TextStyle(
        color: textColor,
        height: 1.4,
      ),
    );
  }

  /// Einfaches Markdown-Parsing für **fett** und _kursiv_
  TextSpan _parseMarkdown(String text, Color baseColor) {
    final List<InlineSpan> spans = [];

    // Regex für **fett** und _kursiv_
    final regex = RegExp(r'\*\*(.+?)\*\*|_(.+?)_');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text vor dem Match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }

      // Fett (**text**)
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ));
      }
      // Kursiv (_text_)
      else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor.withOpacity(0.8),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Restlicher Text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    return TextSpan(
      children: spans.isEmpty
          ? [TextSpan(text: text, style: TextStyle(color: baseColor))]
          : spans,
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedDot(delay: 0, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        _AnimatedDot(delay: 200, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        _AnimatedDot(delay: 400, color: colorScheme.onSurfaceVariant),
      ],
    );
  }
}

/// Animierter Ladeindikator-Punkt
class _AnimatedDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _AnimatedDot({required this.delay, required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
