import 'package:flutter/material.dart';

import '../network.dart';
import '../utils/metro_ui.dart';

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

  const StationPicker({
    super.key,
    required this.title,
  });

  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();

    final matches = metroNetwork.sortedStations.where((station) {
      return station.name.toLowerCase().contains(normalizedQuery);
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
              onChanged: (value) {
                setState(() => query = value);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: matches.isEmpty
                  ? const Center(
                      child: Text('No matching stations'),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final station = matches[index];

                        return ListTile(
                          title: Text(station.name),
                          subtitle: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final line in station.lines)
                                Text(
                                  'Line $line',
                                  style: TextStyle(
                                    color: lineColor(line),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (station.lines.length > 1)
                                const Text('Interchange'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context, station.id);
                          },
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
