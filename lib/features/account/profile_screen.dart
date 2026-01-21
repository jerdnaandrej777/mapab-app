import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/account_provider.dart';

/// Profil-Screen mit Account-Details und Statistiken
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref),
            tooltip: 'Profil bearbeiten',
          ),
        ],
      ),
      body: accountAsync.when(
        data: (account) {
          if (account == null) {
            return const Center(child: Text('Kein Account gefunden'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header mit Avatar und Basics
                _buildHeader(account),

                const Divider(height: 1),

                // Level & XP
                _buildLevelSection(account),

                const Divider(height: 1),

                // Statistiken
                _buildStatisticsSection(account),

                const Divider(height: 1),

                // Achievements
                _buildAchievementsSection(account),

                const Divider(height: 1),

                // Actions
                _buildActionsSection(context, ref, account),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Fehler: $error'),
        ),
      ),
    );
  }

  Widget _buildHeader(account) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: account.avatarUrl != null
                ? ClipOval(
                    child: Image.network(account.avatarUrl!, fit: BoxFit.cover),
                  )
                : Icon(
                    account.isGuest ? Icons.person_outline : Icons.person,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
          ),

          const SizedBox(height: 16),

          // Display Name
          Text(
            account.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Username
          if (!account.isGuest)
            Text(
              '@${account.username}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),

          // Gast-Badge
          if (account.isGuest)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Gast-Account',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.warningColor,
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
                Icon(Icons.email, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  account.email!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
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
              Icon(Icons.devices, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Lokal gespeichert',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(account) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${account.level}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${account.totalXp} XP',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
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
              backgroundColor: AppTheme.backgroundColor,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Noch ${account.xpToNextLevel} XP bis Level ${account.level + 1}',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(account) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiken',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildStatCard(
                icon: Icons.map,
                label: 'Trips',
                value: '${account.totalTripsCreated}',
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.pin_drop,
                label: 'POIs',
                value: '${account.totalPoisVisited}',
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.route,
                label: 'Kilometer',
                value: '${account.totalKmTraveled.toStringAsFixed(0)}',
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
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
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(account) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${account.unlockedAchievements.length}/21',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (account.unlockedAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Noch keine Achievements freigeschaltet. Starte deinen ersten Trip!',
                      style: TextStyle(color: AppTheme.textSecondary),
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
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, account) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Ausloggen'),
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
                label: const Text('Account löschen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Account-Info
          Text(
            'Erstellt am: ${_formatDate(account.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          if (account.lastLoginAt != null)
            Text(
              'Letzter Login: ${_formatDate(account.lastLoginAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
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
    // TODO: Implement edit profile dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil-Bearbeitung kommt bald!')),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ausloggen?'),
        content: const Text('Möchtest du dich wirklich ausloggen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(accountNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Ausloggen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account löschen?'),
        content: const Text(
          'Möchtest du deinen Account wirklich löschen? '
          'Alle Daten werden unwiderruflich gelöscht!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(accountNotifierProvider.notifier).deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
