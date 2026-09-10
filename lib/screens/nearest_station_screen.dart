// Owner: Member 4.
import 'package:flutter/material.dart';

class NearestStationScreen extends StatelessWidget {
  const NearestStationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearest Station')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This feature will be implemented by Member 4.',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

