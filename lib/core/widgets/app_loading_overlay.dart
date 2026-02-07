import 'package:flutter/material.dart';

/// Einheitliches Loading-Overlay für die gesamte App
/// v1.10.23: Zentralisiertes Loading-State System
///
/// Verwendung:
/// ```dart
/// // Einfaches Loading
/// AppLoadingOverlay.show(context);
/// await someAsyncOperation();
/// AppLoadingOverlay.hide(context);
///
/// // Mit Nachricht
/// AppLoadingOverlay.show(context, message: 'Lade Daten...');
///
/// // Mit Fortschritt
/// AppLoadingOverlay.show(context, message: 'Lade POIs...', progress: 0.5);
/// ```
class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  final double? progress;

  const AppLoadingOverlay({
    super.key,
    this.message,
    this.progress,
  });

  /// Zeigt das Loading-Overlay an
  static void show(
    BuildContext context, {
    String? message,
    double? progress,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => AppLoadingOverlay(
        message: message,
        progress: progress,
      ),
    );
  }

  /// Versteckt das Loading-Overlay
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Aktualisiert das Loading-Overlay mit neuem Fortschritt
  /// Hinweis: Erfordert StatefulBuilder oder ähnlichen Ansatz für Updates
  static void updateProgress(
    BuildContext context, {
    String? message,
    double? progress,
  }) {
    hide(context);
    show(context, message: message, progress: progress);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fortschrittsindikator
              if (progress != null)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      Text(
                        '${(progress! * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: colorScheme.primary,
                  ),
                ),

              // Nachricht
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline Loading-Widget für Listen und Cards
/// Verwendet Shimmer-Effekt für visuelles Feedback
class AppLoadingShimmer extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppLoadingShimmer({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius,
  });

  @override
  State<AppLoadingShimmer> createState() => _AppLoadingShimmerState();
}

class _AppLoadingShimmerState extends State<AppLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loading-Indikator für Buttons
class AppButtonLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const AppButtonLoading({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
