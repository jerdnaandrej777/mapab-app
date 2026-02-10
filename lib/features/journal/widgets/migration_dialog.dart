import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/providers/journal_provider.dart';

/// Dialog zur einmaligen Migration von lokalen Journal-Einträgen zur Cloud
class JournalMigrationDialog {
  /// Zeigt den Migration-Dialog an
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal in Cloud sichern?'),
        content: Text(
          'Möchtest du deine lokalen Journal-Einträge und Fotos '
          'in die sichere Cloud hochladen? Dies ermöglicht:\n\n'
          '• Backup bei Geräteverlust\n'
          '• Zugriff von mehreren Geräten\n'
          '• Automatische Synchronisation\n\n'
          'Die Migration kann einige Minuten dauern.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Später'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Jetzt migrieren'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Migriere Einträge...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );

      // Perform migration
      await ref.read(journalNotifierProvider.notifier).migrateLocalToCloud();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration erfolgreich abgeschlossen!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
