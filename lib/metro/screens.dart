import 'package:flutter/material.dart';

import 'network.dart';
import 'online.dart';
import 'routing.dart';
import 'storage.dart';

Color lineColor(int line) {
  switch (line) {
    case 1:
      return const Color(0xFF4275D3);
    case 2:
      return const Color(0xFFB3261E);
    case 3:
      return const Color(0xFF008E66);
    default:
      return const Color(0x40D1D2D1);
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> openMap(BuildContext context, String station) async {
  try {
    await onlineMetro.openStationMap(station);
  } catch (error) {
    if (context.mounted) showMessage(context, error.toString());
  }
}

Future<String?> chooseStation(
    BuildContext context, {
      String title = 'Choose a station',
    }) {
  return showDialog<String>(
    context: context,
    builder: (_) => StationPicker(title: title),
  );
}

class StationPicker extends StatefulWidget {
  final String title;

  const StationPicker({super.key, required this.title});

  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = metroNetwork.sortedStations.where((station) {
      return station.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search station',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No matching stations'))
                  : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (_, index) {
                  final station = matches[index];
                  return ListTile(
                    title: Text(station.name),
                    subtitle: Text(
                      'Line ${station.lines.join(' / ')}'
                          '${station.lines.length > 1 ? ' • Interchange' : ''}',
                    ),
                    onTap: () => Navigator.pop(context, station.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class MetroHome extends StatefulWidget {
  const MetroHome({super.key});

  @override
  State<MetroHome> createState() => _MetroHomeState();
}

class _MetroHomeState extends State<MetroHome> {
  final storage = MetroStorage();

  String start = 'helwan';
  String destination = 'ain_helwan';
  Passenger passenger = Passenger.regular;

  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final data = await storage.load();
      if (!mounted) return;

      if (data['start'] is String &&
          metroNetwork.stations.containsKey(data['start'])) {
        start = data['start'] as String;
      }

      if (data['destination'] is String &&
          metroNetwork.stations.containsKey(data['destination'])) {
        destination = data['destination'] as String;
      }

      passenger = Passenger.values.firstWhere(
            (value) => value.name == data['passenger'],
        orElse: () => Passenger.regular,
      );

      final saved = data['history'];
      if (saved is List) {
        for (final item in saved) {
          if (item is! Map) continue;
          final entry = Map<String, dynamic>.from(item);

          if (metroNetwork.stations.containsKey(entry['start']) &&
              metroNetwork.stations.containsKey(entry['destination'])) {
            history.add(entry);
          }
        }
        history = history.take(20).toList();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, 'Could not restore saved data: $error');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    try {
      await storage.save({
        'start': start,
        'destination': destination,
        'passenger': passenger.name,
        'history': history,
      });
    } catch (error) {
      if (mounted) {
        showMessage(context, 'Could not save locally: $error');
      }
    }
  }

  Future<void> _select(bool selectingStart) async {
    final selected = await chooseStation(
      context,
      title: selectingStart ? 'Start station' : 'Destination station',
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (selectingStart) {
        start = selected;
      } else {
        destination = selected;
      }
    });

    await _save();
  }

  Future<void> _findRoute() async {
    try {
      final journey = RoutePlanner(metroNetwork).find(
        start: start,
        destination: destination,
        passenger: passenger,
      );

      setState(() {
        history.insert(0, {
          'start': start,
          'destination': destination,
          'passenger': passenger.name,
          'fare': journey.fare,
          'minutes': journey.estimatedMinutes,
          'created': DateTime.now().toIso8601String(),
        });

        history = history.take(20).toList();
      });

      await _save();
      if (!mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => JourneyScreen(journey: journey),
        ),
      );
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    }
  }

  Future<void> _showHistory() async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => HistoryPage(entries: List.of(history)),
      ),
    );

    if (selected == null || !mounted) return;

    if (selected['clear'] == true) {
      setState(() => history.clear());
      await _save();
      return;
    }

    setState(() {
      start = selected['start'] as String;
      destination = selected['destination'] as String;
      passenger = Passenger.values.firstWhere(
            (value) => value.name == selected['passenger'],
        orElse: () => Passenger.regular,
      );
    });

    // Recalculate against the current configuration when reopened.
    await _findRoute();
  }

  Future<void> _showNearby(bool useGps) async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => NearbyPage(useGps: useGps),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => start = selected);
    await _save();
  }

  Widget _selector({
    required String title,
    required String id,
    required VoidCallback onTap,
  }) {
    final station = metroNetwork.stations[id]!;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.train_outlined),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${station.name}\nLine ${station.lines.join(' / ')}',
          ),
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: IconButton(
          tooltip: 'Open station map',
          icon: const Icon(Icons.location_on_outlined),
          onPressed: () => openMap(context, station.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cairo Metro Guide'),
        actions: [
          IconButton(
            tooltip: 'Recent trips',
            onPressed: loading ? null : _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Where are you going?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your stations to see the route and train changes.',
              ),
              const SizedBox(height: 20),
              _selector(
                title: 'Start Station',
                id: start,
                onTap: () => _select(true),
              ),
              Center(
                child: IconButton(
                  tooltip: 'Swap stations',
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () async {
                    setState(() {
                      final oldStart = start;
                      start = destination;
                      destination = oldStart;
                    });
                    await _save();
                  },
                ),
              ),
              _selector(
                title: 'Destination Station',
                id: destination,
                onTap: () => _select(false),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Passenger>(
                // Rebuild the field when history restores a category.
                key: ValueKey(passenger),
                initialValue: passenger,
                decoration: const InputDecoration(
                  labelText: 'Passenger category',
                ),
                items: Passenger.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => passenger = value);
                  await _save();
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _findRoute,
                icon: const Icon(Icons.route),
                label: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Find Route'),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showNearby(false),
                    icon: const Icon(Icons.search),
                    label: const Text('Search place'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showNearby(true),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Nearest station'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('Recent trips'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await chooseStation(
                        context,
                        title: 'All stations — choose a start',
                      );
                      if (selected == null || !mounted) return;
                      setState(() => start = selected);
                      await _save();
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('All stations'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Fares use your supplied table, including the senior '
                    'values. Confirm current fares before travel.\n'
                    'This app counts both endpoints for fare bands. '
                    'Travel time is an estimate, not a live prediction.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JourneyScreen extends StatelessWidget {
  final Journey journey;

  const JourneyScreen({super.key, required this.journey});

  Widget _stat(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your route')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${metroNetwork.name(journey.start)} → '
                    '${metroNetwork.name(journey.destination)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _stat('Stations incl. endpoints', '${journey.stationCount}'),
                  _stat('Stops traveled', '${journey.stops}'),
                  _stat('Train changes', '${journey.changes}'),
                  _stat('Fare', 'EGP ${journey.fare}'),
                  _stat('Estimated time', '${journey.estimatedMinutes} min'),
                  _stat('Passenger', journey.passenger.label),
                ],
              ),
              const SizedBox(height: 12),
              if (journey.stops == 0)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'You selected the same station. No journey is needed.',
                    ),
                  ),
                ),
              for (var index = 0; index < journey.legs.length; index++) ...[
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Change trains at '
                          '${metroNetwork.name(journey.legs[index].stationIds.first)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                _legCard(context, journey.legs[index], index),
              ],
              const SizedBox(height: 20),
              const Text(
                'Route preference: fewest stops, then fewest train changes.\n'
                    'Time estimate: 2.5 minutes per stop + 5 minutes per change. '
                    'Initial waiting time and live delays are excluded.\n'
                    'Fare bands use your supplied configuration and count both '
                    'endpoints; confirm the fare convention before travel.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legCard(BuildContext context, JourneyLeg leg, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. Line ${leg.line}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: lineColor(leg.line),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Board toward ${metroNetwork.name(leg.direction)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Get off at ${metroNetwork.name(leg.stationIds.last)}'
                  ' • ${leg.stops} stops',
            ),
            const Divider(),
            for (var i = 0; i < leg.stationIds.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i == 0 || i == leg.stationIds.length - 1
                      ? Icons.radio_button_checked
                      : Icons.circle_outlined,
                  color: lineColor(leg.line),
                ),
                title: Text(metroNetwork.name(leg.stationIds[i])),
                trailing: IconButton(
                  tooltip: 'Open station map',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => openMap(
                    context,
                    metroNetwork.name(leg.stationIds[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const HistoryPage({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent trips'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Clear recent trips?'),
                    content: const Text('This removes the saved trip list.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  Navigator.pop(context, <String, dynamic>{'clear': true});
                }
              },
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('Calculate a route to save your first trip.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (_, index) {
          final entry = entries[index];
          final when = DateTime.tryParse(
            entry['created']?.toString() ?? '',
          );

          return Card(
            child: ListTile(
              title: Text(
                '${metroNetwork.name(entry['start'] as String)} → '
                    '${metroNetwork.name(entry['destination'] as String)}',
              ),
              subtitle: Text(
                'Saved fare: EGP ${entry['fare']}'
                    ' • ${entry['minutes']} min\n'
                    '${when?.toLocal().toString().split('.').first ?? ''}\n'
                    'Tap to recalculate with current settings.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, entry),
            ),
          );
        },
      ),
    );
  }
}

class NearbyPage extends StatefulWidget {
  final bool useGps;

  const NearbyPage({super.key, required this.useGps});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final controller = TextEditingController();

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
      if (mounted) setState(() => error = problem.toString());
    } finally {
      if (mounted) setState(() => busy = false);
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
      if (mounted) setState(() => error = problem.toString());
    } finally {
      if (mounted) setState(() => busy = false);
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
      if (mounted) setState(() => nearby = results);
    } catch (problem) {
      if (mounted) setState(() => error = problem.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _map(MapPlace place) async {
    try {
      await onlineMetro.openPlaceMap(place);
    } catch (problem) {
      if (mounted) showMessage(context, problem.toString());
    }
  }

  Future<void> _useStation(MapPlace place) async {
    // Do not silently guess between differently spelled OSM station names.
    final selected = await chooseStation(
      context,
      title: 'Select ${place.name} in the route list',
    );

    if (selected != null && mounted) {
      Navigator.pop(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.useGps ? 'Nearest station' : 'Search a place'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
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
                  'Closest returned subway stations by straight-line distance. '
                      'Walking routes may be longer.',
                ),
                if (nearby.first.meters > 50000)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Your selected location is far from the Cairo network.',
                    ),
                  ),
                for (final result in nearby)
                  Card(
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
                  ),
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
              InkWell(
                onTap: () => _openAttribution(),
                child: const Text(
                  'Place and station locations: © OpenStreetMap contributors. '
                      'Search: Photon. Locations: Overpass.\n'
                      'Online coverage and service availability may vary.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttribution() async {
    // Attribution text remains visible even if the link cannot be opened.
    await _map(
      const MapPlace(
        name: 'Cairo',
        latitude: 30.0444,
        longitude: 31.2357,
      ),
    );
  }
}