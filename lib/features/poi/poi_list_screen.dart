import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import 'widgets/poi_card.dart';
import 'widgets/poi_filters.dart';

/// POI-Listen-Screen
class POIListScreen extends ConsumerStatefulWidget {
  const POIListScreen({super.key});

  @override
  ConsumerState<POIListScreen> createState() => _POIListScreenState();
}

class _POIListScreenState extends ConsumerState<POIListScreen> {
  String _searchQuery = '';
  Set<POICategory> _selectedCategories = {};
  bool _mustSeeOnly = false;
  double _maxDetour = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sehenswürdigkeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'POIs durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Quick Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Must-See',
                  icon: '⭐',
                  isSelected: _mustSeeOnly,
                  onTap: () => setState(() => _mustSeeOnly = !_mustSeeOnly),
                ),
                const SizedBox(width: 8),
                ...POICategory.values.take(5).map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat.label,
                        icon: cat.icon,
                        isSelected: _selectedCategories.contains(cat),
                        onTap: () {
                          setState(() {
                            if (_selectedCategories.contains(cat)) {
                              _selectedCategories.remove(cat);
                            } else {
                              _selectedCategories.add(cat);
                            }
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // POI-Liste (Placeholder)
          Expanded(
            child: _buildPOIList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPOIList() {
    // TODO: Echte POI-Daten aus State laden
    // Aktuell: Placeholder mit Demo-Daten

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Demo
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: POICard(
            name: 'Sehenswürdigkeit ${index + 1}',
            category: POICategory.values[index % POICategory.values.length],
            distance: '${(index + 1) * 5} km',
            rating: 3.5 + (index % 3) * 0.5,
            reviewCount: 100 + index * 50,
            isMustSee: index % 3 == 0,
            imageUrl: null,
            onTap: () => context.push('/poi/demo-$index'),
            onAddToTrip: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zur Route hinzugefügt'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => POIFiltersSheet(
        selectedCategories: _selectedCategories,
        mustSeeOnly: _mustSeeOnly,
        maxDetour: _maxDetour,
        onApply: (categories, mustSee, detour) {
          setState(() {
            _selectedCategories = categories;
            _mustSeeOnly = mustSee;
            _maxDetour = detour;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
