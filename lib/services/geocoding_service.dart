import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from geocoding with metadata
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

class GeocodingService {
  final _client = http.Client();

  /// Get coordinates for an address using Nominatim (OpenStreetMap)
  Future<Map<String, double>?> getCoordinates(String address) async {
    if (address.trim().isEmpty) {
      print('GeocodingService: Empty address provided');
      return null;
    }

    final cleanedAddress = address.trim();
    print('GeocodingService: Starting geocoding for "$cleanedAddress"');

    // Try full address first
    var result = await _tryNominatim(cleanedAddress);
    if (result != null) {
      print('GeocodingService: SUCCESS with full address!');
      return {'latitude': result.latitude, 'longitude': result.longitude};
    }

    // Try progressive fallback with simpler queries
    result = await _progressiveFallback(cleanedAddress);
    if (result != null) {
      print('GeocodingService: SUCCESS with fallback!');
      return {'latitude': result.latitude, 'longitude': result.longitude};
    }

    print('GeocodingService: FAILED - Could not geocode "$cleanedAddress"');
    return null;
  }

  /// Try Nominatim geocoding service (OpenStreetMap)
  Future<GeocodingResult?> _tryNominatim(String query) async {
    try {
      // Nominatim requires 1 second between requests - be respectful
      await Future.delayed(const Duration(milliseconds: 1100));

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&accept-language=en,es',
      );

      print('GeocodingService: Searching "$query"');

      final response = await _client
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'BCardScanner/1.0 (Flutter business card scanning app; contact: github.com/user)',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          final displayName = data[0]['display_name']?.toString() ?? query;

          if (lat != null && lon != null) {
            print('GeocodingService: FOUND! $lat, $lon → "$displayName"');
            return GeocodingResult(
              latitude: lat,
              longitude: lon,
              displayName: displayName,
            );
          }
        }
        print('GeocodingService: No results for "$query"');
      } else {
        print('GeocodingService: HTTP ${response.statusCode} for "$query"');
      }
    } catch (e) {
      print('GeocodingService: Error - $e');
    }
    return null;
  }

  /// Progressive fallback - try simpler parts of the address
  Future<GeocodingResult?> _progressiveFallback(String address) async {
    // Clean the address first
    final cleaned = _cleanAddress(address);

    // Split by common delimiters
    final parts = cleaned
        .split(RegExp(r'[,;\n]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p.length > 2)
        .toList();

    print('GeocodingService: Fallback with ${parts.length} parts: $parts');

    // Strategy 1: Try removing specific parts from the start (street number, etc.)
    for (int skip = 1; skip < parts.length; skip++) {
      final broaderAddress = parts.sublist(skip).join(', ');
      if (broaderAddress.length < 3) continue;

      print('GeocodingService: Trying broader "$broaderAddress"');
      var result = await _tryNominatim(broaderAddress);
      if (result != null) return result;
    }

    // Strategy 2: Try individual parts from most general to specific
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (_isNumeric(part)) continue;

      print('GeocodingService: Trying individual "$part"');
      var result = await _tryNominatim(part);
      if (result != null) return result;
    }

    // Strategy 3: Try known location patterns
    final extracted = _extractKnownLocation(address);
    if (extracted != null && extracted != address) {
      print('GeocodingService: Trying extracted "$extracted"');
      return await _tryNominatim(extracted);
    }

    // Strategy 4: Try just the last 2 parts (usually city, country)
    if (parts.length >= 2) {
      final lastTwo = parts.sublist(parts.length - 2).join(', ');
      print('GeocodingService: Trying last two "$lastTwo"');
      var result = await _tryNominatim(lastTwo);
      if (result != null) return result;
    }

    return null;
  }

  /// Clean address by removing common noise
  String _cleanAddress(String address) {
    return address
        .replaceAll(RegExp(r'#\d+'), '') // Remove #123 style numbers
        .replaceAll(RegExp(r'\bpiso\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfloor\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bsuite\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bste\.?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bapt\.?\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\bpte\.?\b', caseSensitive: false),
          '',
        ) // "poniente" abrev
        .replaceAll(
          RegExp(r'\bnte\.?\b', caseSensitive: false),
          '',
        ) // "norte" abrev
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isNumeric(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length > s.length / 2;
  }

  String? _extractKnownLocation(String address) {
    // Try to match "City, ST" pattern (US)
    final cityState = RegExp(
      r'([A-Za-z\s]+),?\s*([A-Z]{2})\s*\d*',
    ).firstMatch(address);
    if (cityState != null) {
      final city = cityState.group(1)?.trim();
      final state = cityState.group(2);
      if (city != null && state != null && city.isNotEmpty) {
        return '$city, $state, USA';
      }
    }

    // Known locations to try extracting
    final knownPlaces = {
      'cancun': 'Cancún, Mexico',
      'cancún': 'Cancún, Mexico',
      'mexico': 'Mexico',
      'méxico': 'Mexico',
      'quintana roo': 'Quintana Roo, Mexico',
      'quinta roo': 'Quintana Roo, Mexico',
      'florida': 'Florida, USA',
      'california': 'California, USA',
      'texas': 'Texas, USA',
      'new york': 'New York, USA',
      'miami': 'Miami, Florida, USA',
      'hialeah': 'Hialeah, Florida, USA',
      'los angeles': 'Los Angeles, California, USA',
      'madrid': 'Madrid, Spain',
      'barcelona': 'Barcelona, Spain',
    };

    final lowerAddress = address.toLowerCase();
    for (final entry in knownPlaces.entries) {
      if (lowerAddress.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
