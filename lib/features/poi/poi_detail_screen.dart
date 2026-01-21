import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/format_utils.dart';

/// POI-Detail-Screen
class POIDetailScreen extends ConsumerWidget {
  final String poiId;

  const POIDetailScreen({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: POI aus State laden
    // Aktuell: Demo-Daten

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar mit Bild
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.black),
                ),
                onPressed: () {
                  // TODO: Zu Favoriten hinzufügen
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.black),
                ),
                onPressed: () {
                  // TODO: Teilen
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Demo-Bild
                  Container(
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Text('🏰', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Kategorie
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schloss Neuschwanstein',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '🏰 Schlösser & Burgen',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Must-See',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bewertung
                  _buildRatingSection(),

                  const SizedBox(height: 24),

                  // Route-Info
                  _buildRouteInfoSection(),

                  const SizedBox(height: 24),

                  // Beschreibung
                  const Text(
                    'Über diesen Ort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Das Schloss Neuschwanstein steht oberhalb von Hohenschwangau bei Füssen im südöstlichen bayerischen Allgäu. Der Bau wurde ab 1869 für den bayerischen König Ludwig II. als idealisierte Vorstellung einer Ritterburg aus der Zeit des Mittelalters errichtet.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kontakt-Info
                  _buildContactSection(),

                  const SizedBox(height: 100), // Space für FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Zur Route hinzufügen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zur Route hinzugefügt')),
          );
          context.pop();
        },
        icon: const Icon(Icons.add),
        label: const Text('Zur Route'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Sterne
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (index) {
                    if (index < 4) {
                      return const Icon(Icons.star,
                          size: 20, color: Colors.amber);
                    }
                    return const Icon(Icons.star_half,
                        size: 20, color: Colors.amber);
                  }),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '4.8 von 5 (2.453 Bewertungen)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Verifiziert Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified,
                    size: 16, color: AppTheme.successColor),
                const SizedBox(width: 4),
                Text(
                  'Verifiziert',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.route,
            label: 'Umweg',
            value: '+12 km',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
          _buildInfoItem(
            icon: Icons.timer,
            label: 'Zeit',
            value: '+15 Min.',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
          _buildInfoItem(
            icon: Icons.place,
            label: 'Position',
            value: '45%',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kontakt & Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildContactTile(
          icon: Icons.access_time,
          title: 'Öffnungszeiten',
          subtitle: 'Mo-So 9:00 - 18:00',
        ),
        _buildContactTile(
          icon: Icons.phone,
          title: 'Telefon',
          subtitle: '+49 8362 930830',
          onTap: () => launchUrl(Uri.parse('tel:+4983629308300')),
        ),
        _buildContactTile(
          icon: Icons.language,
          title: 'Website',
          subtitle: 'neuschwanstein.de',
          onTap: () => launchUrl(Uri.parse('https://www.neuschwanstein.de')),
        ),
        _buildContactTile(
          icon: Icons.email,
          title: 'E-Mail',
          subtitle: 'info@neuschwanstein.de',
          onTap: () => launchUrl(Uri.parse('mailto:info@neuschwanstein.de')),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.open_in_new,
              size: 18, color: AppTheme.textSecondary)
          : null,
      onTap: onTap,
    );
  }
}
