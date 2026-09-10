// Owner: Member 1 — UI shell and navigation only.
import 'package:flutter/material.dart';
import '../data/metro_data.dart';
import '../models/trip_result.dart';
import '../utils/app_constants.dart';
import '../widgets/primary_button.dart';
import '../widgets/station_selector.dart';
import 'history_screen.dart';
import 'nearest_station_screen.dart';
import 'place_search_screen.dart';
import 'result_screen.dart';
import 'station_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppConstants.underDevelopment)),
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed demo stations; selection and persistence are not implemented.
    final start = metroStations[0];
    final destination = metroStations[1];

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Architecture preview • Dummy stations only'),
            const SizedBox(height: 16),
            StationSelector(
              title: 'Start Station',
              selectedStation: start,
              onTap: () => _showPlaceholder(context),
              onLocationPressed: () =>
                  _openScreen(context, StationMapScreen(station: start)),
            ),
            Center(
              child: IconButton(
                tooltip: 'Swap stations',
                icon: const Icon(Icons.swap_vert),
                onPressed: () => _showPlaceholder(context),
              ),
            ),
            StationSelector(
              title: 'Destination Station',
              selectedStation: destination,
              onTap: () => _showPlaceholder(context),
              onLocationPressed: () =>
                  _openScreen(context, StationMapScreen(station: destination)),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Find Route',
              onPressed: () {
                // UI preview only. Do not call the unfinished route service.
                final demoTrip = TripResult(
                  start: start,
                  destination: destination,
                  route: [start, destination],
                  stationCount: 2,
                  ticketPrice: 0,
                  estimatedMinutes: 0,
                  transferStations: const [],
                );
                _openScreen(context, ResultScreen(trip: demoTrip));
              },
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Place'),
              onTap: () => _openScreen(context, const PlaceSearchScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Nearest Station'),
              onTap: () => _openScreen(context, const NearestStationScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Recent Trips'),
              onTap: () => _openScreen(context, const HistoryScreen()),
            ),
            
          ],
        ),
      ),
    );
  }
}
