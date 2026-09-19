import 'package:flutter/material.dart';

import '../network.dart';
import '../routing.dart';
import '../storage.dart';
import '../utils/metro_ui.dart';
import '../widgets/station_picker.dart';
import '../widgets/station_selection_card.dart';
import 'all_stations_screen.dart';
import 'history_screen.dart';
import 'journey_screen.dart';
import 'nearby_screen.dart';

class MetroHome extends StatefulWidget {
  const MetroHome({super.key});

  @override
  State<MetroHome> createState() => _MetroHomeState();
}

class _MetroHomeState extends State<MetroHome> {
  final MetroStorage storage = MetroStorage();

  String start = 'helwan';
  String destination = 'ain_helwan';
  Passenger passenger = Passenger.regular;

  RoutePreference routePreference = RoutePreference.fewestChanges;

  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  // Older saved data without a preference defaults to fewer interchanges.
  RoutePreference _readPreference(Object? savedValue) {
    return RoutePreference.values.firstWhere(
      (value) => value.name == savedValue,
      orElse: () => RoutePreference.fewestChanges,
    );
  }

  Future<void> _restore() async {
    try {
      final data = await storage.load();
      if (!mounted) return;

      final savedStart = data['start'];
      final savedDestination = data['destination'];

      if (savedStart is String &&
          metroNetwork.stations.containsKey(savedStart)) {
        start = savedStart;
      }

      if (savedDestination is String &&
          metroNetwork.stations.containsKey(savedDestination)) {
        destination = savedDestination;
      }

      passenger = Passenger.values.firstWhere(
        (value) => value.name == data['passenger'],
        orElse: () => Passenger.regular,
      );

      routePreference = _readPreference(data['routePreference']);

      final restoredHistory = <Map<String, dynamic>>[];
      final savedHistory = data['history'];

      if (savedHistory is List) {
        for (final item in savedHistory) {
          if (item is! Map) continue;

          final entry = Map<String, dynamic>.from(item);

          if (metroNetwork.stations.containsKey(entry['start']) &&
              metroNetwork.stations.containsKey(entry['destination'])) {
            restoredHistory.add(entry);
          }
        }
      }

      history = restoredHistory.take(20).toList();
    } catch (error) {
      if (mounted) {
        showMessage(context, 'Could not restore saved data: $error');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _save() async {
    try {
      await storage.save({
        'start': start,
        'destination': destination,
        'passenger': passenger.name,
        'routePreference': routePreference.name,
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

  Future<void> _swap() async {
    setState(() {
      final previousStart = start;
      start = destination;
      destination = previousStart;
    });

    await _save();
  }

  Future<void> _findRoute() async {
    try {
      final journey = RoutePlanner(metroNetwork).find(
        start: start,
        destination: destination,
        passenger: passenger,
        preference: routePreference,
      );

      setState(() {
        history.insert(0, {
          'start': journey.start,
          'destination': journey.destination,
          'passenger': journey.passenger.name,
          'routePreference': journey.preference.name,
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
      if (mounted) {
        showMessage(context, error.toString());
      }
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

      routePreference = _readPreference(selected['routePreference']);
    });

    // Recalculate using the saved preference.
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

  Future<void> _showAllStations() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const AllStationsPage(),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => start = selected);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cairo Metro Guide'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Where are you going?',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your stations to see the route '
                            'and train changes.',
                          ),
                          const SizedBox(height: 20),
                          StationSelectionCard(
                            title: 'Start Station',
                            station: metroNetwork.stations[start]!,
                            onTap: () => _select(true),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: IconButton.filledTonal(
                                tooltip: 'Swap start and destination',
                                icon: const Icon(Icons.swap_vert),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: _swap,
                              ),
                            ),
                          ),
                          StationSelectionCard(
                            title: 'Destination Station',
                            station: metroNetwork.stations[destination]!,
                            onTap: () => _select(false),
                          ),
                          const SizedBox(height: 16),

                          // Passenger category.
                          DropdownButtonFormField<Passenger>(
                            key: ValueKey(passenger),
                            initialValue: passenger,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Passenger category',
                            ),
                            items: Passenger.values.map((type) {
                              return DropdownMenuItem<Passenger>(
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

                          // Route preference.
                          DropdownButtonFormField<RoutePreference>(
                            key: ValueKey(routePreference),
                            initialValue: routePreference,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Route preference',
                              prefixIcon: Icon(Icons.alt_route),
                            ),
                            items: RoutePreference.values.map((preference) {
                              return DropdownMenuItem<RoutePreference>(
                                value: preference,
                                child: Text(preference.label),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() => routePreference = value);
                              await _save();
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            routePreference.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                                onPressed: _showAllStations,
                                icon: const Icon(Icons.list),
                                label: const Text('All stations'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fares are indicative. Confirm before travel. '
                                  'Journey times are estimates.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.only(bottom: 12),
                            title: Text(
                              'How fares and times are estimated',
                              style: TextStyle(fontSize: 13),
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '• Fare bands currently count both the start '
                                  'and destination stations. This counting '
                                  'convention needs confirmation.\n\n'
                                  '• Configured fares have not been verified '
                                  'as current official prices, including '
                                  'senior fares.\n\n'
                                  '• Journey time uses 2.5 minutes per traveled '
                                  'stop plus 5 minutes per train change.\n\n'
                                  '• Initial waiting time, walking and live '
                                  'delays are excluded.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
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
