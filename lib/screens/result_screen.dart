// Owner: Member 1 — result UI; Member 2 supplies the future route result.
import 'package:flutter/material.dart';
import '../models/trip_result.dart';
import '../widgets/trip_summary_card.dart';

class ResultScreen extends StatelessWidget {
  final TripResult trip;
  const ResultScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Result — Demo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Route calculation will be implemented by Member 2.',
                  textAlign: TextAlign.center),
              TripSummaryCard(trip: trip),
            ],
          ),
        ),
      ),
    );
  }
}
