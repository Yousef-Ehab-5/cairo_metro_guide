// Owner: Member 5.
import 'package:flutter/material.dart';

class PlaceSearchScreen extends StatelessWidget {
  const PlaceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Place')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This feature will be implemented by Member 5.',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

