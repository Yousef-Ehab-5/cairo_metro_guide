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

  static const Color _blue = Color(0xFF175CD3);
  static const Color _red = Color(0xFFB3261E);
  static const Color _green = Color(0xFF13795B);

  Widget _stat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 20,
        color: color,
      ),
      label: Text('$label: $value'),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withAlpha(60),
        ),
      ),
    );
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

                    // Journey information with icons.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _stat(
                          icon: Icons.train_outlined,
                          label: 'Stations incl. endpoints',
                          value: '${journey.stationCount}',
                          color: _blue,
                        ),
                        _stat(
                          icon: Icons.route_outlined,
                          label: 'Stops traveled',
                          value: '${journey.stops}',
                          color: _blue,
                        ),
                        _stat(
                          icon: Icons.swap_horiz,
                          label: 'Train changes',
                          value: '${journey.changes}',
                          color: _red,
                        ),
                        _stat(
                          icon: Icons.payments_outlined,
                          label: 'Fare',
                          value: 'EGP ${journey.fare}',
                          color: _green,
                        ),
                        _stat(
                          icon: Icons.schedule,
                          label: 'Estimated time',
                          value: formatMinutes(journey.estimatedMinutes),
                          color: _blue,
                        ),
                        _stat(
                          icon: Icons.person_outline,
                          label: 'Passenger',
                          value: journey.passenger.label,
                          color: _green,
                        ),
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

                    // Journey legs and interchange instructions.
                    for (var index = 0;
                    index < journey.legs.length;
                    index++) ...[
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.swap_horiz,
                                color: _red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
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
                            ],
                          ),
                        ),
                      _legCard(context, journey.legs[index], index),
                    ],

                    const SizedBox(height: 20),
                    Text(
                      'Route preference: ${journey.preference.description}\n'
                          'Time estimate: 2.5 minutes per stop + 5 minutes per '
                          'change. Initial waiting time and live delays are '
                          'excluded.\n'
                          'Fares are indicative. Confirm before travel.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                      ),
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
    final color = lineColor(leg.line);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.train_outlined,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${index + 1}. Line ${leg.line}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Board toward ${metroNetwork.name(leg.direction)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
                  color: color,
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

String formatMinutes(int totalMinutes) {
  if (totalMinutes < 60) {
    return '$totalMinutes min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (minutes == 0) {
    return '$hours hr';
  }

  return '$hours hr $minutes min';
}