import 'package:flutter/material.dart';

import '../online.dart';
import '../utils/metro_ui.dart';
import '../widgets/station_picker.dart';

class NearbyPage extends StatefulWidget {
  final bool useGps;

  const NearbyPage({
    super.key,
    required this.useGps,
  });

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final TextEditingController controller = TextEditingController();

  bool busy = false;
  String? error;
  String status = '';

  MapPlace? origin;
  List<MapPlace> places = [];
  List<NearbyStation> nearby = [];

  @override
  void initState() {
    super.initState();

    if (widget.useGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _gps();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _gps() async {
    if (busy) return;

    setState(() {
      busy = true;
      error = null;
      origin = null;
      places = [];
      nearby = [];
      status = 'Getting your location…';
    });

    try {
      final location = await onlineMetro.currentLocation();
      if (!mounted) return;

      setState(() {
        origin = location;
        status = 'Finding nearby subway stations…';
      });

      final results = await onlineMetro.nearest(location);
      if (!mounted) return;

      setState(() => nearby = results);
    } catch (problem) {
      if (mounted) {
        setState(() => error = problem.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _search() async {
    if (busy) return;

    setState(() {
      busy = true;
      error = null;
      origin = null;
      nearby = [];
      places = [];
      status = 'Searching places…';
    });

    try {
      final results = await onlineMetro.searchPlaces(controller.text);
      if (!mounted) return;

      setState(() {
        places = results;

        if (results.isEmpty) {
          error = 'No places found. Try a more specific street or place name.';
        }
      });
    } catch (problem) {
      if (mounted) {
        setState(() => error = problem.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _selectPlace(MapPlace place) async {
    if (busy) return;

    setState(() {
      origin = place;
      busy = true;
      nearby = [];
      error = null;
      status = 'Finding nearby subway stations…';
    });

    try {
      final results = await onlineMetro.nearest(place);

      if (mounted) {
        setState(() => nearby = results);
      }
    } catch (problem) {
      if (mounted) {
        setState(() => error = problem.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _map(MapPlace place) async {
    try {
      await onlineMetro.openPlaceMap(place);
    } catch (problem) {
      if (mounted) {
        showMessage(context, problem.toString());
      }
    }
  }

  Future<void> _useStation(MapPlace place) async {
    final selected = await chooseStation(
      context,
      title: 'Select ${place.name} in the route list',
    );

    if (selected != null && mounted) {
      Navigator.pop(context, selected);
    }
  }

  Widget _nearbyCard(NearbyStation result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.place.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${(result.meters / 1000).toStringAsFixed(2)} km',
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _map(result.place),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open map'),
                ),
                TextButton(
                  onPressed: () => _useStation(result.place),
                  child: const Text('Choose as route start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.useGps ? 'Nearest station' : 'Search a place',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.useGps) ...[
                      TextField(
                        controller: controller,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Place or street in Greater Cairo',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: busy ? null : _search,
                        child: const Text('Search'),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: busy ? null : _gps,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Refresh my location'),
                      ),
                    if (busy) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(status),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (origin != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Near ${origin!.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (origin!.description.isNotEmpty)
                        Text(origin!.description),
                    ],
                    if (nearby.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Closest returned subway stations by straight-line '
                        'distance. Walking routes may be longer.',
                      ),
                      if (nearby.first.meters > 50000)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Your selected location is far from '
                            'the Cairo network.',
                          ),
                        ),
                      for (final result in nearby) _nearbyCard(result),
                    ],
                    if (!busy && places.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Select the correct search result:'),
                      for (final place in places)
                        Card(
                          child: ListTile(
                            title: Text(place.name),
                            subtitle: Text(place.description),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _selectPlace(place),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Place and station locations: '
                      '© OpenStreetMap contributors.\n'
                      'Search: Photon. Locations: Overpass.\n'
                      'Online coverage and service availability may vary.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
