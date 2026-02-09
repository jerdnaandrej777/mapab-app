import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../data/providers/gallery_provider.dart';
import 'widgets/public_trip_card.dart';

/// Oeffentliches Creator-Profil.
class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider(widget.userId).notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider(widget.userId));
    final colorScheme = Theme.of(context).colorScheme;
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.displayNameOrDefault ?? context.l10n.profileTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(profileNotifierProvider(widget.userId).notifier)
              .loadProfile();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isLoading && profile == null) ...[
              const SizedBox(height: 80),
              const Center(child: CircularProgressIndicator()),
            ] else if (state.error != null && profile == null) ...[
              const SizedBox(height: 48),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 44, color: colorScheme.error),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(
                                profileNotifierProvider(widget.userId).notifier)
                            .loadProfile();
                      },
                      child: Text(context.l10n.galleryRetry),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (profile != null) ...[
                _ProfileHeader(state: state),
                const SizedBox(height: 20),
              ],
              Text(
                context.l10n.galleryAllTrips,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (state.trips.isEmpty)
                Text(
                  context.l10n.galleryNoTrips,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else
                ...state.trips.map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PublicTripCard(
                      trip: trip,
                      showAuthor: false,
                      onTap: () => context.push('/gallery/${trip.id}'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileState state;

  const _ProfileHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = state.profile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayNameOrDefault,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.bio!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
