import 'package:flutter/material.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';

/// Fehler-Anzeige Widget
class ErrorView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel,
  });

  /// Netzwerk-Fehler
  factory ErrorView.network({required BuildContext context, VoidCallback? onRetry}) {
    final l10n = context.l10n;
    return ErrorView(
      title: l10n.errorNetwork,
      message: l10n.errorNetworkMessage,
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Server-Fehler
  factory ErrorView.server({required BuildContext context, VoidCallback? onRetry}) {
    final l10n = context.l10n;
    return ErrorView(
      title: l10n.errorServer,
      message: l10n.errorServerMessage,
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  /// Keine Ergebnisse
  factory ErrorView.empty({
    required BuildContext context,
    String? title,
    String? message,
  }) {
    return ErrorView(
      title: title ?? context.l10n.errorNoResults,
      message: message,
      icon: Icons.search_off,
    );
  }

  /// Standort-Fehler
  factory ErrorView.location({required BuildContext context, VoidCallback? onRetry}) {
    final l10n = context.l10n;
    return ErrorView(
      title: l10n.errorLocation,
      message: l10n.errorLocationMessage,
      icon: Icons.location_off,
      onRetry: onRetry,
      retryLabel: l10n.openSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
