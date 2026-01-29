import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/route.dart';
import '../../../data/repositories/geocoding_repo.dart';
import '../providers/random_trip_provider.dart';

/// Widget zur Auswahl des Startpunkts (manuelle Eingabe Standard, GPS als Fallback)
class StartLocationPicker extends ConsumerStatefulWidget {
  const StartLocationPicker({super.key});

  @override
  ConsumerState<StartLocationPicker> createState() => _StartLocationPickerState();
}

class _StartLocationPickerState extends ConsumerState<StartLocationPicker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(GeocodingResult result) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    notifier.setStartLocation(result.location, result.shortName ?? result.displayName);
    _controller.text = result.shortName ?? result.displayName;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controller mit aktuellem Wert synchronisieren
    if (state.startAddress != null && _controller.text.isEmpty) {
      _controller.text = state.startAddress!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Startpunkt',
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),

        // Adress-Eingabefeld (Standard)
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.hasValidStart && !state.useGPS
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: state.hasValidStart && !state.useGPS ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Stadt oder Adresse eingeben...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _suggestions = []);
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _searchAddress,
              ),

              // Vorschläge
              if (_suggestions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                  ),
                  child: Column(
                    children: _suggestions.map<Widget>((result) => InkWell(
                      onTap: () => _selectSuggestion(result),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.shortName ?? result.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (result.shortName != null)
                                    Text(
                                      result.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // GPS als sekundäre Option
        _GpsButton(
          isLoading: state.isLoading && state.useGPS,
          isSelected: state.useGPS && state.hasValidStart,
          address: state.useGPS ? state.startAddress : null,
          onTap: () => notifier.useCurrentLocation(),
        ),

        // Fehler anzeigen
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => notifier.clearError(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GpsButton extends StatelessWidget {
  final bool isLoading;
  final bool isSelected;
  final String? address;
  final VoidCallback onTap;

  const _GpsButton({
    required this.isLoading,
    required this.isSelected,
    this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.my_location,
                size: 18,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            const SizedBox(width: 8),
            Text(
              address ?? 'GPS-Standort verwenden',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
