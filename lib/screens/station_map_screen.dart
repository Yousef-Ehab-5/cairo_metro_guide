// Owner: Member 3.
import 'package:flutter/material.dart';
import '../models/station.dart';

class StationMapScreen extends StatelessWidget {
  final Station? station;
  const StationMapScreen({super.key, this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station Location')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${station?.nameEn ?? "No station selected"}\n'
            'This feature will be implemented by Member 3.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
