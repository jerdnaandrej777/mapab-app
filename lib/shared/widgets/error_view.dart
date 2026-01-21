import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fehler-Anzeige Widget
class ErrorView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorView({
    super.key,
    this.title = 'Ein Fehler ist aufgetreten',
    this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel = 'Erneut versuchen',
  });

  /// Netzwerk-Fehler
  factory ErrorView.network({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Keine Internetverbindung',
      message: 'Bitte überprüfe deine Verbindung und versuche es erneut.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Server-Fehler
  factory ErrorView.server({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Server nicht erreichbar',
      message: 'Der Server antwortet nicht. Versuche es später erneut.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  /// Keine Ergebnisse
  factory ErrorView.empty({
    String title = 'Keine Ergebnisse',
    String? message,
  }) {
    return ErrorView(
      title: title,
      message: message,
      icon: Icons.search_off,
    );
  }

  /// Standort-Fehler
  factory ErrorView.location({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Standort nicht verfügbar',
      message: 'Bitte erlaube den Zugriff auf deinen Standort.',
      icon: Icons.location_off,
      onRetry: onRetry,
      retryLabel: 'Einstellungen öffnen',
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
                color: AppTheme.errorColor.withOpacity(0.1),
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
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
