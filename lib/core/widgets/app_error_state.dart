import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

/// Einheitliches Error-State Widget für die gesamte App
/// v1.10.23: Zentralisiertes Error-Handling
///
/// Verwendung:
/// ```dart
/// // Einfacher Fehler
/// AppErrorState(message: 'Verbindungsfehler')
///
/// // Mit Retry
/// AppErrorState(
///   message: 'Laden fehlgeschlagen',
///   onRetry: () => loadData(),
/// )
///
/// // Kompakt (für Listen)
/// AppErrorState.compact(
///   message: 'Fehler',
///   onRetry: retry,
/// )
/// ```
class AppErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const AppErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.compact = false,
  });

  /// Kompakte Variante für Inline-Fehler
  const AppErrorState.compact({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : compact = true;

  /// Netzwerk-Fehler Variante
  factory AppErrorState.network({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppErrorState(
      key: key,
      message: message,
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Leere Daten Variante
  factory AppErrorState.empty({
    Key? key,
    required String message,
    String? details,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return _AppEmptyState(
      key: key,
      message: message,
      details: details,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 14,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                color: colorScheme.primary,
                tooltip: context.l10n.retry,
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Leerer Zustand (keine Daten)
class _AppEmptyState extends AppErrorState {
  final VoidCallback? onAction;
  final String? actionLabel;

  const _AppEmptyState({
    super.key,
    required super.message,
    super.details,
    this.onAction,
    this.actionLabel,
  }) : super(icon: Icons.inbox_outlined);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Snackbar-Helper für einheitliche Fehler-Anzeige
class AppSnackbar {
  /// Zeigt eine Erfolgs-Snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// Zeigt eine Fehler-Snackbar
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
      duration: const Duration(seconds: 4),
    );
  }

  /// Zeigt eine Info-Snackbar
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
    );
  }

  /// Zeigt eine Warn-Snackbar
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      textColor: Theme.of(context).colorScheme.onTertiaryContainer,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
