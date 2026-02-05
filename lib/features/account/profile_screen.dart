import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../data/providers/account_provider.dart';
import '../../data/providers/auth_provider.dart';

/// Profil-Screen mit Account-Details und Statistiken
/// Unterstützt sowohl Cloud-Auth (Supabase) als auch lokale Accounts
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final authState = ref.watch(authNotifierProvider);
    final accountAsync = ref.watch(accountNotifierProvider);

    // Cloud-User hat Priorität
    if (authState.isAuthenticated && authState.user != null) {
      return _buildCloudUserProfile(context, ref, authState, accountAsync);
    }

    // Lokaler Account (Gast)
    return accountAsync.when(
      data: (account) {
        if (account == null) {
          return _buildNoAccountView(context, colorScheme);
        }
        return _buildLocalAccountProfile(context, ref, account);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.l10n.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.profileTitle)),
        body: Center(
          child: Text('${context.l10n.errorGeneric}: $error', style: TextStyle(color: colorScheme.error)),
        ),
      ),
    );
  }

  /// Zeigt Profil für Cloud-authentifizierte User (Supabase)
  Widget _buildCloudUserProfile(
    BuildContext context,
    WidgetRef ref,
    AppAuthState authState,
    AsyncValue<dynamic> accountAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Versuche lokale Account-Daten zu holen (für Statistiken)
    final localAccount = accountAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref),
            tooltip: context.l10n.profileEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header mit Cloud-User Info
            _buildCloudHeader(context, authState, isDark, colorScheme),

            const Divider(height: 1),

            // Level & XP (falls lokale Daten vorhanden)
            if (localAccount != null) ...[
              _buildLevelSection(context, localAccount),
              const Divider(height: 1),
              _buildStatisticsSection(context, localAccount),
              const Divider(height: 1),
              _buildAchievementsSection(context, localAccount),
              const Divider(height: 1),
            ] else ...[
              // Placeholder für Cloud-Only User
              _buildCloudStatsPlaceholder(context, colorScheme),
              const Divider(height: 1),
            ],

            // Actions (Logout, etc.)
            _buildCloudActionsSection(context, ref, authState),
          ],
        ),
      ),
    );
  }

  /// Header für Cloud-User
  Widget _buildCloudHeader(
    BuildContext context,
    AppAuthState authState,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.cloud,
              size: 50,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Display Name
          Text(
            authState.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          if (authState.userEmail != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  authState.userEmail!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Cloud-Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: isDark ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.profileCloudAccount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sync-Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                context.l10n.profileAutoSync,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Placeholder für Cloud-User ohne lokale Statistiken
  Widget _buildCloudStatsPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.profileStatisticsLoading,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileStartFirstTrip,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Actions für Cloud-User
  Widget _buildCloudActionsSection(BuildContext context, WidgetRef ref, AppAuthState authState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCloudLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.profileLogout),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account-Info
          if (authState.userId != null)
            Text(
              context.l10n.profileAccountId('${authState.userId!.substring(0, 8)}...'),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  /// Cloud Logout Dialog
  void _showCloudLogoutDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.profileLogoutTitle),
        content: Text(context.l10n.profileLogoutCloudMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Cloud-Logout
              await ref.read(authNotifierProvider.notifier).signOut();

              // Lokaler Account-Logout
              await ref.read(accountNotifierProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(context.l10n.profileLogout),
          ),
        ],
      ),
    );
  }

  /// Kein Account View - Weiterleitung zum Login
  Widget _buildNoAccountView(BuildContext context, ColorScheme colorScheme) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.profileNoAccount,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.profileLoginPrompt,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Text(context.l10n.profileLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lokales Profil (Gast-Modus) - bestehende Implementierung mit Dark Mode Fixes
  Widget _buildLocalAccountProfile(BuildContext context, WidgetRef ref, dynamic account) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref),
            tooltip: context.l10n.profileEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, account),
            const Divider(height: 1),
            _buildLevelSection(context, account),
            const Divider(height: 1),
            _buildStatisticsSection(context, account),
            const Divider(height: 1),
            _buildAchievementsSection(context, account),
            const Divider(height: 1),
            _buildActionsSection(context, ref, account),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: account.avatarUrl != null
                ? ClipOval(
                    child: Image.network(account.avatarUrl!, fit: BoxFit.cover),
                  )
                : Icon(
                    account.isGuest ? Icons.person_outline : Icons.person,
                    size: 50,
                    color: colorScheme.primary,
                  ),
          ),

          const SizedBox(height: 16),

          // Display Name
          Text(
            account.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          // Username
          if (!account.isGuest)
            Text(
              '@${account.username}',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

          // Gast-Badge
          if (account.isGuest)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                context.l10n.profileGuestAccount,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Email
          if (account.email != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  account.email!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // Account-Typ
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_android, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                context.l10n.profileLocalStorage,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, dynamic account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.profileLevel(account.level),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${account.totalXp} XP',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: account.levelProgress,
              minHeight: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            context.l10n.profileXpProgress(account.xpToNextLevel, account.level + 1),
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, dynamic account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profileStatistics,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildStatCard(
                context: context,
                icon: Icons.map,
                label: context.l10n.profileTrips,
                value: '${account.totalTripsCreated}',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context: context,
                icon: Icons.pin_drop,
                label: context.l10n.profilePois,
                value: '${account.totalPoisVisited}',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context: context,
                icon: Icons.route,
                label: context.l10n.profileKilometers,
                value: '${account.totalKmTraveled.toStringAsFixed(0)}',
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, dynamic account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.profileAchievements,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${account.unlockedAchievements.length}/21',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (account.unlockedAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.profileNoAchievements,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: account.unlockedAchievements.map<Widget>((id) {
                return Chip(
                  label: Text(id),
                  avatar: const Icon(Icons.emoji_events, size: 18),
                  backgroundColor: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, dynamic account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Upgrade zu Cloud-Account
          if (account.isGuest) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/register'),
                icon: const Icon(Icons.cloud_upload),
                label: Text(context.l10n.profileUpgradeToCloud),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.profileLogout),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          if (!account.isGuest) ...[
            const SizedBox(height: 12),

            // Account löschen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                icon: const Icon(Icons.delete_forever),
                label: Text(context.l10n.profileDeleteAccount),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Account-Info
          Text(
            context.l10n.profileCreatedAt(_formatDate(account.createdAt)),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (account.lastLoginAt != null)
            Text(
              context.l10n.profileLastLogin(_formatDate(account.lastLoginAt!)),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileEditComingSoon)),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.profileLogoutTitle),
        content: Text(context.l10n.profileLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Cloud-Logout (wenn eingeloggt)
              final authState = ref.read(authNotifierProvider);
              if (authState.isAuthenticated) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }

              // Lokaler Account-Logout
              await ref.read(accountNotifierProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(context.l10n.profileLogout),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.profileDeleteTitle),
        content: Text(context.l10n.profileDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(accountNotifierProvider.notifier).deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}
