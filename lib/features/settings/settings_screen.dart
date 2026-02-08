import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/category_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/settings_provider.dart';

/// Einstellungen Screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  static const String _appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: 'unknown');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          // Erscheinungsbild Sektion
          _SectionHeader(title: context.l10n.settingsAppearance),
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
            title: context.l10n.settingsAutoDarkMode,
            subtitle: context.l10n.settingsAutoDarkModeDesc,
            trailing: Switch(
              value: settings.autoSunsetDarkMode,
              onChanged: (value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setAutoSunsetDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Feedback Sektion
          _SectionHeader(title: context.l10n.settingsFeedback),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.vibration,
            title: context.l10n.settingsHaptic,
            subtitle: context.l10n.settingsHapticDesc,
            trailing: Switch(
              value: settings.hapticFeedback,
              onChanged: (value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setHapticFeedback(value);
              },
            ),
          ),

          _SettingsTile(
            icon: Icons.volume_up,
            title: context.l10n.settingsSound,
            subtitle: context.l10n.settingsSoundDesc,
            trailing: Switch(
              value: settings.soundEffects,
              onChanged: (value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setSoundEffects(value);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Sprache Sektion
          _SectionHeader(title: context.l10n.settingsLanguage),
          const SizedBox(height: AppSpacing.sm),

          _LanguageSelector(
            currentLanguage: settings.language,
            onChanged: (lang) {
              ref.read(settingsNotifierProvider.notifier).setLanguage(lang);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info Sektion
          _SectionHeader(title: context.l10n.settingsAbout),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.info_outline,
            title: context.l10n.settingsAppVersion,
            subtitle: _appVersion,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.code,
            title: context.l10n.settingsLicenses,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: context.l10n.appName,
                applicationVersion: _appVersion,
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
                    context.l10n.settingsDesign,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
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
              mode.localizedLabel(context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
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
        trailing: trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}

/// Unterstützte Sprachen
const _supportedLanguages = [
  ('de', 'Deutsch', '🇩🇪'),
  ('en', 'English', '🇬🇧'),
  ('fr', 'Français', '🇫🇷'),
  ('it', 'Italiano', '🇮🇹'),
  ('es', 'Español', '🇪🇸'),
];

/// Sprachauswahl Widget
class _LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({
    required this.currentLanguage,
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
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.settingsLanguage,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _supportedLanguages.map((lang) {
                final isSelected = lang.$1 == currentLanguage;
                return _LanguageOption(
                  code: lang.$1,
                  name: lang.$2,
                  flag: lang.$3,
                  isSelected: isSelected,
                  onTap: () => onChanged(lang.$1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Einzelne Sprach-Option
class _LanguageOption extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
