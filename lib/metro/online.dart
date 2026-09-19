import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MapPlace {
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  const MapPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description = '',
  });
}

class NearbyStation {
  final MapPlace place;
  final double meters;

  const NearbyStation(this.place, this.meters);
}

class OnlineMetro {
  List<MapPlace>? _stationCache;

  Future<MapPlace> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Enable location services on your device.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission was denied. '
        'Allow location in your browser or device settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );

    return MapPlace(
      name: 'Your location',
      latitude: position.latitude,
      longitude: position.longitude,
      description: 'Reported accuracy: ${position.accuracy.round()} meters',
    );
  }

  Future<List<MapPlace>> searchPlaces(String query) async {
    final text = query.trim();

    if (text.length < 3) {
      throw Exception('Enter at least 3 characters.');
    }

    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': text,
      'lang': 'en',
      'limit': '8',
      'lat': '30.0444',
      'lon': '31.2357',
      'bbox': '30.8,29.6,31.9,30.5',
    });

    final headers = <String, String>{
      'Accept': 'application/json',

      // Browsers manage their own User-Agent header.
      if (!kIsWeb) 'User-Agent': 'CairoMetroGuide/1.0',
    };

    late final http.Response response;

    try {
      response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw Exception(
        'Place search took too long. Please try again later.',
      );
    } on http.ClientException {
      throw Exception(
        'Could not connect to place search. Check your connection.',
      );
    }

    if (response.statusCode != 200) {
      // Inspect the server's explanation during development.
      // Do not show raw server responses in the app interface.
      if (kDebugMode) {
        final body = utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        );

        final preview =
        body.length > 500 ? body.substring(0, 500) : body;

        debugPrint('Place search HTTP ${response.statusCode}');
        debugPrint('Server response: $preview');
      }

      if (response.statusCode == 403) {
        throw Exception(
          'The place-search service refused this request. '
              'Search is currently unavailable.',
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          'Too many search requests. Please wait before searching again.',
        );
      }

      throw Exception(
        'Place search is unavailable (${response.statusCode}). '
            'Please try again later.',
      );
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (body is! Map || body['features'] is! List) {
        throw const FormatException('Missing search results.');
      }

      final results = <MapPlace>[];

      for (final feature in body['features'] as List) {
        if (feature is! Map) continue;

        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties is! Map || geometry is! Map) continue;
        if (geometry['type'] != 'Point') continue;

        final coordinates = geometry['coordinates'];

        if (coordinates is! List || coordinates.length < 2) {
          continue;
        }

        final lon = coordinates[0];
        final lat = coordinates[1];

        if (lon is! num || lat is! num) continue;

        final longitude = lon.toDouble();
        final latitude = lat.toDouble();

        if (!longitude.isFinite ||
            !latitude.isFinite ||
            longitude < -180 ||
            longitude > 180 ||
            latitude < -90 ||
            latitude > 90) {
          continue;
        }

        final description = [
          properties['street'],
          properties['district'],
          properties['city'],
          properties['state'],
        ]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .join(', ');

        results.add(
          MapPlace(
            name: properties['name']?.toString() ??
                properties['street']?.toString() ??
                'Search result',
            description: description,
            longitude: longitude,
            latitude: latitude,
          ),
        );
      }

      return results;
    } on FormatException {
      throw Exception(
        'The place-search service returned an invalid response.',
      );
    }
  }

  Future<List<MapPlace>> _loadSubwayStations() async {
    if (_stationCache != null) return _stationCache!;

    // Fetch station features rather than inventing coordinates.
    // Bounding box covers Greater Cairo.
    const query = '''
[out:json][timeout:30];
nwr["railway"="station"]["station"="subway"]
(29.6,30.8,30.5,31.9);
out center tags;
''';

    final uri = Uri.https(
      'overpass-api.de',
      '/api/interpreter',
    );

    final response = await http.post(
      uri,
      headers: {
        'Accept': '*/*',
        if (!kIsWeb) 'User-Agent': 'CairoMetroGuide/1.0',
      },
      body: {'data': query},
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      if (kDebugMode) {
        final body = utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        );

        final preview =
        body.length > 500 ? body.substring(0, 500) : body;

        debugPrint('Station lookup HTTP ${response.statusCode}');
        debugPrint('Station response: $preview');
      }

      throw Exception(
        'Could not load metro station locations '
            '(${response.statusCode}). Please try again later.',
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (body['remark'] != null) {
      throw Exception('Station lookup could not complete. Please retry.');
    }

    final places = <MapPlace>[];
    final seen = <String>{};

    for (final element in body['elements'] as List? ?? []) {
      final tags = Map<String, dynamic>.from(
        element['tags'] as Map? ?? {},
      );

      final center = element['center'] as Map?;
      final lat = element['lat'] ?? center?['lat'];
      final lon = element['lon'] ?? center?['lon'];

      if (lat is! num || lon is! num) continue;

      final name = tags['name:en']?.toString() ??
          tags['name']?.toString() ??
          'Subway station';

      // OSM may contain both a point and an area for a station.
      if (!seen.add(name.toLowerCase())) continue;

      places.add(
        MapPlace(
          name: name,
          description: tags['name']?.toString() ?? '',
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
        ),
      );
    }

    if (places.isEmpty) {
      throw Exception('No subway station locations were returned.');
    }

    _stationCache = places;
    return places;
  }

  Future<List<NearbyStation>> nearest(MapPlace origin) async {
    final stations = await _loadSubwayStations();

    final ranked = stations.map((station) {
      final meters = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        station.latitude,
        station.longitude,
      );
      return NearbyStation(station, meters);
    }).toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));

    return ranked.take(5).toList();
  }

  Future<void> openStationMap(String name) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$name metro station Cairo Egypt',
    });

    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      throw Exception('Could not open Google Maps.');
    }
  }

  Future<void> openPlaceMap(MapPlace place) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${place.latitude},${place.longitude}',
    });

    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      throw Exception('Could not open Google Maps.');
    }
  }
}

final onlineMetro = OnlineMetro();
