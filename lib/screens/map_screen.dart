import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/business_card.dart';
import '../data/database_helper.dart';
import '../services/geocoding_service.dart';

class MapScreen extends StatefulWidget {
  final List<BusinessCard> cards;
  final VoidCallback? onLocationsUpdated;

  const MapScreen({super.key, required this.cards, this.onLocationsUpdated});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isUpdating = false;
  int _cardsWithoutLocation = 0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateStats();
  }

  void _calculateStats() {
    _cardsWithoutLocation = widget.cards
        .where((c) => c.latitude == null && c.address.isNotEmpty)
        .length;
  }

  Future<void> _updateLocations() async {
    final cardsToUpdate = widget.cards
        .where(
          (c) =>
              c.latitude == null && c.longitude == null && c.address.isNotEmpty,
        )
        .toList();

    if (cardsToUpdate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All contacts already have locations!')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Updating Locations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing ${cardsToUpdate.length} contacts...'),
            const SizedBox(height: 8),
            const Text(
              'This may take a moment.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;
    final geocodingService = GeocodingService();

    for (final card in cardsToUpdate) {
      try {
        debugPrint('Geocoding: ${card.name} - "${card.address}"');
        final coords = await geocodingService.getCoordinates(card.address);

        if (coords != null) {
          final updatedCard = card.copyWith(
            latitude: coords['latitude'],
            longitude: coords['longitude'],
          );
          await DatabaseHelper.instance.updateCard(updatedCard);
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
        debugPrint('Error geocoding ${card.name}: $e');
      }
    }

    // Close dialog
    if (mounted) Navigator.pop(context);

    setState(() => _isUpdating = false);

    // Notify parent to refresh
    widget.onLocationsUpdated?.call();

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated $successCount locations${failCount > 0 ? ", $failCount failed" : ""}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter valid locations first
    final validLocationCards = widget.cards
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();

    // 2. Get unique categories
    final categories = ['All', ...widget.cards.map((c) => c.category).toSet().toList()..sort()];

    // 3. Apply category filter
    final displayCards = _selectedCategory == 'All'
        ? validLocationCards
        : validLocationCards.where((c) => c.category == _selectedCategory).toList();

    final hasCardsToUpdate = widget.cards.any(
      (c) => c.latitude == null && c.address.isNotEmpty,
    );

    // Empty state when no cards have locations (globally, not just filtered)
    if (validLocationCards.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                Text(
                  'No locations to show',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasCardsToUpdate
                      ? 'You have ${_cardsWithoutLocation} contacts with addresses.\nTap the button below to find their locations.'
                      : 'Add addresses to your contacts to see them on the map.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                if (hasCardsToUpdate) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateLocations,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_searching),
                    label: Text(_isUpdating ? 'Updating...' : 'Find Locations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Calculate center based on displayed cards, fallback to validLocationCards or default
    LatLng center;
    if (displayCards.isNotEmpty) {
      double latSum = 0;
      double longSum = 0;
      for (var card in displayCards) {
        latSum += card.latitude!;
        longSum += card.longitude!;
      }
      center = LatLng(
        latSum / displayCards.length,
        longSum / displayCards.length,
      );
    } else if (validLocationCards.isNotEmpty) {
       // If filter returns empty, center on all valid cards (or keep previous center? this is simpler)
       double latSum = 0;
       double longSum = 0;
       for (var card in validLocationCards) {
         latSum += card.latitude!;
         longSum += card.longitude!;
       }
       center = LatLng(
         latSum / validLocationCards.length,
         longSum / validLocationCards.length,
       );
    } else {
      center = const LatLng(0, 0); // Should be handled by empty check above
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            // Key helps to redraw map when center changes significantly if needed,
            // but MapOptions usually handles updates if unique.
            // We might want to keep the same map instance to avoid flickering.
            options: MapOptions(
              initialCenter: center,
              initialZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bcard_scanner',
              ),
              MarkerLayer(
                markers: displayCards.map((card) {
                  return Marker(
                    point: LatLng(card.latitude!, card.longitude!),
                    width: 100,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26),
                            ],
                          ),
                          child: Text(
                            card.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 32,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Category Filters
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black26,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Stats badge (Moved to bottom left)
          Positioned(
            bottom: 32,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Colors.black26),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 6),
                  Text(
                    '${displayCards.length} found',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // FAB to update locations (only show if there are cards without locations)
      floatingActionButton: hasCardsToUpdate
          ? FloatingActionButton.extended(
              onPressed: _isUpdating ? null : _updateLocations,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.location_searching),
              label: Text(
                _isUpdating ? 'Updating...' : 'Update $_cardsWithoutLocation',
              ),
            )
          : null,
    );
  }
}
