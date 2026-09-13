import 'package:flutter/material.dart';

import '../network.dart';
import '../utils/metro_ui.dart';

class AllStationsPage extends StatelessWidget {
  const AllStationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All stations'),
          bottom: TabBar(
            tabs: [
              _lineTab(1),
              _lineTab(2),
              _lineTab(3),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _linePage(
                context,
                line: 1,
                sections: {
                  'Helwan ↔ New El-Marg': line1Names,
                },
              ),
              _linePage(
                context,
                line: 2,
                sections: {
                  'Shubra El-Kheima ↔ El-Mounib': line2Names,
                },
              ),
              _linePage(
                context,
                line: 3,
                sections: {
                  'Shared section: Adly Mansour ↔ Kit Kat':
                  line3SharedNames,
                  'From Kit Kat → Rod El-Farag Corridor':
                  line3RodNames,
                  'From Kit Kat → Cairo University':
                  line3UniversityNames,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineTab(int line) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: lineColor(line),
          ),
          const SizedBox(width: 8),
          Text('Line $line'),
        ],
      ),
    );
  }

  Widget _linePage(
      BuildContext context, {
        required int line,
        required Map<String, List<String>> sections,
      }) {
    return ListView(
      key: PageStorageKey<String>('station-list-line-$line'),
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tap a station to use it as your start station. '
                      'Tap the map icon to view its location.',
                ),
                if (line == 3) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Line 3 splits at Kit Kat. '
                        'Both branches are listed separately below.',
                  ),
                ],
                for (final section in sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Text(
                      section.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        color: lineColor(line),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final name in section.value)
                    _stationCard(
                      context,
                      station: metroNetwork.stations[stationId(name)]!,
                      line: line,
                    ),
                ],
                if (line == 3)
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 12),
                    child: Text(
                      'Monorail connections are shown for reference. '
                          'Check service availability before travel. '
                          'Route calculation currently covers metro '
                          'services only.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stationCard(
      BuildContext context, {
        required MetroStation station,
        required int line,
      }) {
    final otherLines = station.lines
        .where((number) => number != line)
        .toList();

    final monorail = monorailConnections[station.id];

    return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            Icons.train,
            color: lineColor(line),
          ),
          title: Text(
            station.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: otherLines.isEmpty && monorail == null
              ? null
              : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  for (final otherLine in otherLines)
              Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '↔ Interchange with Metro Line $otherLine',
            style: TextStyle(
              color: lineColor(otherLine),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (monorail != null)
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.tram_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Monorail connection: $monorail',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ), // Closes Row
                  ],     // Closes Column's children list
              ),       // Closes Column
          ),         // Closes Padding
          trailing: IconButton(
    tooltip: 'Open station map',
    icon: const Icon(Icons.map_outlined),
    onPressed: () => openStationMap(context, station.name),
    ),
    onTap: () => Navigator.pop(context, station.id),
    ),
    );
  }
}