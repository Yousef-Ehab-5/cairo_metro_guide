import 'package:flutter/material.dart';

import '../network.dart';
import '../routing.dart';
import '../utils/metro_ui.dart';

class JourneyScreen extends StatelessWidget {
  final Journey journey;

  const JourneyScreen({
    super.key,
    required this.journey,
  });

  Widget _stat(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your route'),
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
                        _stat(
                          'Stations incl. endpoints',
                          '${journey.stationCount}',
                        ),
                        _stat('Stops traveled', '${journey.stops}'),
                        _stat('Train changes', '${journey.changes}'),
                        _stat('Fare', 'EGP ${journey.fare}'),
                        _stat(
                          'Estimated time',
                          '${journey.estimatedMinutes} min',
                        ),
                        _stat('Passenger', journey.passenger.label),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (journey.stops == 0)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'You selected the same station. '
                            'No journey is needed.',
                          ),
                        ),
                      ),
                    for (var index = 0;
                        index < journey.legs.length;
                        index++) ...[
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Change trains at '
                            '${metroNetwork.name(
                              journey.legs[index].stationIds.first,
                            )}',
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
                      'Route preference: fewest stops, then fewest train '
                      'changes.\n'
                      'Time estimate: 2.5 minutes per stop + 5 minutes per '
                      'change. Initial waiting time and live delays are '
                      'excluded.\n'
                      'Fares are indicative. Confirm before travel.',
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

  Widget _legCard(
    BuildContext context,
    JourneyLeg leg,
    int index,
  ) {
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
                title: Text(
                  metroNetwork.name(leg.stationIds[i]),
                ),
                trailing: IconButton(
                  tooltip: 'Open station map',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => openStationMap(
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
