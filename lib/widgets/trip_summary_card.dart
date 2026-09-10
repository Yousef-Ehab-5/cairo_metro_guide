// Owner: Member 1. Member 2 supplies TripResult after integration.
import 'package:flutter/material.dart';
import '../models/trip_result.dart';

class TripSummaryCard extends StatelessWidget {
  final TripResult trip;
  const TripSummaryCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${trip.start.nameEn} → ${trip.destination.nameEn}'),
            const SizedBox(height: 8),
            const Text('Demo preview — no route has been calculated.'),
            const Text('Station count: Under development'),
            const Text('Ticket price: Under development'),
            const Text('Estimated time: Under development'),
            const Text('Transfers: Under development'),
            // TODO(Member 1): Show verified result fields after integration.
          ],
        ),
      ),
    );
  }
}
