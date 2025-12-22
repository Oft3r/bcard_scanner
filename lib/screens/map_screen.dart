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
    final validCards = widget.cards
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();
    final hasCardsToUpdate = widget.cards.any(
      (c) => c.latitude == null && c.address.isNotEmpty,
    );

    // Empty state when no cards have locations
    if (validCards.isEmpty) {
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

    // Calculate center
    double latSum = 0;
    double longSum = 0;
    for (var card in validCards) {
      latSum += card.latitude!;
      longSum += card.longitude!;
    }
    final center = LatLng(
      latSum / validCards.length,
      longSum / validCards.length,
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 4.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bcard_scanner',
              ),
              MarkerLayer(
                markers: validCards.map((card) {
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
          // Stats badge
          Positioned(
            top: 60,
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
                    '${validCards.length} on map',
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
