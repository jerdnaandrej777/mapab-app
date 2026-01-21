import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/settings_provider.dart';

/// Einstellungen Screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Erscheinungsbild Sektion
          _SectionHeader(title: 'Erscheinungsbild'),
          const SizedBox(height: AppSpacing.sm),

          // Theme Auswahl
          _ThemeSelector(
            currentMode: settings.themeMode,
            onChanged: (mode) {
              ref.read(settingsNotifierProvider.notifier).setThemeMode(mode);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Auto Dark Mode bei Sonnenuntergang
          _SettingsTile(
            icon: Icons.nights_stay,
            title: 'Auto Dark Mode',
            subtitle: 'Automatisch bei Sonnenuntergang aktivieren',
            trailing: Switch(
              value: settings.autoSunsetDarkMode,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setAutoSunsetDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Feedback Sektion
          _SectionHeader(title: 'Feedback'),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.vibration,
            title: 'Haptisches Feedback',
            subtitle: 'Vibrationen bei Interaktionen',
            trailing: Switch(
              value: settings.hapticFeedback,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setHapticFeedback(value);
              },
            ),
          ),

          _SettingsTile(
            icon: Icons.volume_up,
            title: 'Sound-Effekte',
            subtitle: 'Töne bei Aktionen',
            trailing: Switch(
              value: settings.soundEffects,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setSoundEffects(value);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info Sektion
          _SectionHeader(title: 'Über'),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App-Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),

          _SettingsTile(
            icon: Icons.code,
            title: 'Open Source Lizenzen',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Travel Planner',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Sektion Header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

/// Theme Auswahl Widget
class _ThemeSelector extends StatelessWidget {
  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onChanged;

  const _ThemeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Design',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: AppThemeMode.values.map((mode) {
                final isSelected = mode == currentMode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ThemeOption(
                      mode: mode,
                      isSelected: isSelected,
                      onTap: () => onChanged(mode),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Einzelne Theme Option
class _ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 28,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}
