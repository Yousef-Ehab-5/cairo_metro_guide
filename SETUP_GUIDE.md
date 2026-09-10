# Cairo Metro Guide — complete architecture guide

All 12 steps, exact file paths, full code and explanations. Architecture only.


## Step 1 — Create the Flutter project

Run these commands on your computer with Flutter installed:

```bash
flutter doctor
flutter create cairo_metro_guide
cd cairo_metro_guide
```

In Android Studio, choose **File → Open**, select `cairo_metro_guide` (the folder
containing pubspec.yaml), and open it. Enable the Flutter and Dart IDE plugins if
they are not already installed. Select an Android emulator or connected phone.

You can copy this archive’s project contents into the generated project now,
replacing matching files, then read the remaining steps as explanations. Keep
the generated platform folders and .gitignore. Alternatively, create each file
below manually. Complete all files before running: some files import later steps.


## Step 2 — Create the folders

Inside lib, create models, data, screens, widgets, services, utils and theme using Android Studio’s New → Directory. Keep test at the project root.

| Folder | Responsibility |
| --- | --- |
| models/ | Shared data contracts; no widgets, GPS or routing logic |
| data/ | Sample station and connection lists; Member 2 later supplies verified data |
| screens/ | Complete pages that use widgets and eventually call services |
| widgets/ | Small reusable UI pieces |
| services/ | Future route, location, search and storage behavior |
| utils/ | Future calculations and shared constants |
| theme/ | Shared colors and Material appearance |
| test/ | Navigation smoke test; feature tests come with implementations |


## Step 3 — Create shared models

These shared contracts are owned by Member 1. Agree on changes before editing them.

### Create `station.dart`

**File path:** `cairo_metro_guide/lib/models/station.dart`

`Station` is the common station data shape. `lines` is a List<int> because an interchange can belong to multiple lines. `final` prevents field reassignment; it does not by itself make a passed-in list immutable. Use const lists or avoid mutating lists shared between features.

```dart
// Owner: Member 1. Discuss shared model changes with the team first.
class Station {
  final String id;
  final String nameEn;
  final String nameAr;
  // Interchange stations may belong to several lines.
  final List<int> lines;
  final double latitude;
  final double longitude;

  const Station({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.lines,
    required this.latitude,
    required this.longitude,
  });
}
```

### Create `metro_connection.dart`

**File path:** `cairo_metro_guide/lib/models/metro_connection.dart`

A connection describes a link between station IDs on one line. It is graph data, not a route algorithm. Member 2 will decide how bidirectional travel and branches are represented.

```dart
// Owner: Member 1 — shared contract; Member 2 owns connection data.
class MetroConnection {
  final String fromStationId;
  final String toStationId;
  final int line;

  const MetroConnection({
    required this.fromStationId,
    required this.toStationId,
    required this.line,
  });
}

// TODO(Member 2): Build the graph and define how reverse edges are represented.
```

### Create `trip_result.dart`

**File path:** `cairo_metro_guide/lib/models/trip_result.dart`

UI and routing agree on one output shape. The comments define units and ID meanings. `required` forces callers to supply a value. `const` allows constant objects when their arguments are constant.

```dart
// Owner: Member 1 — shared output contract for route and UI developers.
import 'station.dart';

class TripResult {
  final Station start;
  final Station destination;
  // Ordered stations, including both endpoints.
  final List<Station> route;
  // Contract: number of stations in route, including both endpoints.
  // Member 2 must check fare-counting rules separately before implementation.
  final int stationCount;
  // Egyptian pounds, not piasters. Placeholder previews are not real fares.
  final int ticketPrice;
  final double estimatedMinutes;
  // Station IDs, not display names. Resolve names using metro data.
  final List<String> transferStations;

  const TripResult({
    required this.start,
    required this.destination,
    required this.route,
    required this.stationCount,
    required this.ticketPrice,
    required this.estimatedMinutes,
    required this.transferStations,
  });
}
```

## Step 4 — Add placeholder data

This is deliberately not a real metro database.

### Create `metro_data.dart`

**File path:** `cairo_metro_guide/lib/data/metro_data.dart`

Five deliberately synthetic stations exercise the shared model, including an interchange. Zero coordinates must be replaced before location work. The connection list stays empty.

```dart
// Owner: Member 2.
import '../models/station.dart';
import '../models/metro_connection.dart';

// TODO(Member 2): Replace this sample data with the complete verified
// Cairo Metro Lines 1, 2 and 3 data, including branches and connections.
// DEMO ONLY: names, line assignments and coordinates are synthetic.
// Coordinates 0, 0 are placeholders and MUST NOT be used for maps or GPS.
// TODO(Member 3): Validate every real station coordinate with Member 2.
const List<Station> metroStations = [
  Station(id: 'demo_a', nameEn: 'Demo Station A', nameAr: 'محطة تجريبية أ',
    lines: [1], latitude: 0, longitude: 0),
  Station(id: 'demo_b', nameEn: 'Demo Station B', nameAr: 'محطة تجريبية ب',
    lines: [1], latitude: 0, longitude: 0),
  Station(id: 'demo_c', nameEn: 'Demo Interchange C', nameAr: 'محطة تبادل تجريبية ج',
    lines: [1, 2], latitude: 0, longitude: 0),
  Station(id: 'demo_d', nameEn: 'Demo Station D', nameAr: 'محطة تجريبية د',
    lines: [2], latitude: 0, longitude: 0),
  Station(id: 'demo_e', nameEn: 'Demo Station E', nameAr: 'محطة تجريبية هـ',
    lines: [3], latitude: 0, longitude: 0),
];

// TODO(Member 2): Add verified neighboring-station connections.
const List<MetroConnection> metroConnections = [];
```

## Step 5 — Create TODO services and utilities

Service bodies remain stubs. The UI does not call these unfinished services.

### Create `route_service.dart`

**File path:** `cairo_metro_guide/lib/services/route_service.dart`

`Station` inputs and a nullable `TripResult?` output establish the route interface. `null` is only a stub here. There is no graph search.

```dart
// Owner: Member 2.
import '../models/station.dart';
import '../models/trip_result.dart';

class RouteService {
  TripResult? findRoute({required Station start, required Station destination}) {
    // TODO(Member 2): Implement graph route calculation and transfers.
    // null currently means the feature has not been implemented.
    return null;
  }
}
```

### Create `location_service.dart`

**File path:** `cairo_metro_guide/lib/services/location_service.dart`

`Future<void>` prepares an asynchronous operation without returning a location yet. Agree on a typed coordinate result with the leader when implementing GPS.

```dart
// Owner: Member 4.
class LocationService {
  Future<void> getCurrentLocation() async {
    // TODO(Member 4): Agree on a coordinate result type with Member 1.
    // TODO(Member 4): Implement geolocator, permissions and GPS error handling.
  }
}
```

### Create `place_search_service.dart`

**File path:** `cairo_metro_guide/lib/services/place_search_service.dart`

The query parameter is the future search input. No request or geocoding occurs. The future result model must be agreed before integration.

```dart
// Owner: Member 5.
class PlaceSearchService {
  Future<void> searchPlace(String query) async {
    // TODO(Member 5): Agree on a place result model with Member 1.
    // TODO(Member 5): Implement place/street search and handle no results.
    // Coordinate with Member 4 to reuse future nearest-station logic.
  }
}
```

### Create `storage_service.dart`

**File path:** `cairo_metro_guide/lib/services/storage_service.dart`

The methods reserve entry points for saving/restoring selections and history. These async stubs perform no persistence. The empty list does not mean that history has been loaded.

```dart
// Owner: Member 5.
import '../models/station.dart';
import '../models/trip_result.dart';

class StorageService {
  Future<void> saveLastTrip({
    required Station start,
    required Station destination,
  }) async {
    // TODO(Member 5): Save station IDs using shared_preferences.
  }

  Future<void> loadLastTrip() async {
    // TODO(Member 5): Agree on a saved-selection return model with Member 1.
    // Restore station IDs and handle removed or missing stations.
  }

  Future<void> saveRecentTrip(TripResult trip) async {
    // TODO(Member 5): Persist a completed trip after route integration.
  }

  Future<List<TripResult>> loadRecentTrips() async {
    // TODO(Member 5): Read recent trips. Empty list is a placeholder only.
    return [];
  }
}
```

### Create `fare_calculator.dart`

**File path:** `cairo_metro_guide/lib/utils/fare_calculator.dart`

`static` allows FareCalculator.calculate(...) without constructing an object. Zero is a temporary return value, not a fare rule.

```dart
// Owner: Member 2.
class FareCalculator {
  static int calculate(int stationCount) {
    // TODO(Member 2): Verify and implement current Cairo Metro fare rules.
    // Zero is a stub, NOT a free fare. Do not display it as a real quote.
    return 0;
  }
}
```

### Create `time_calculator.dart`

**File path:** `cairo_metro_guide/lib/utils/time_calculator.dart`

Named inputs make station and transfer counts explicit. No timing formula exists yet.

```dart
// Owner: Member 2.
class TimeCalculator {
  static double calculate({
    required int stationCount,
    required int transferCount,
  }) {
    // TODO(Member 2): Implement and document travel-time assumptions.
    // Zero is a stub, not an actual travel estimate.
    return 0;
  }
}
```

### Create `app_constants.dart`

**File path:** `cairo_metro_guide/lib/utils/app_constants.dart`

App-wide names are kept together so repeated values have one source.

```dart
// Owner: Member 1.
class AppConstants {
  static const String appName = 'Cairo Metro Guide';
  static const String underDevelopment = 'Feature under development';
}
```

## Step 6 — Create screens

Each feature has an independent screen. The home screen connects only placeholders.

### Create `nearest_station_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/nearest_station_screen.dart`

This page gives the assigned feature its own AppBar and centered ownership message; no feature behavior is implemented.

```dart
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
// TODO(Member 4): Implement this feature in your feature branch.
```

### Create `place_search_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/place_search_screen.dart`

This page gives the assigned feature its own AppBar and centered ownership message; no feature behavior is implemented.

```dart
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
// TODO(Member 5): Implement this feature in your feature branch.
```

### Create `history_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/history_screen.dart`

This page gives the assigned feature its own AppBar and centered ownership message; no feature behavior is implemented.

```dart
// Owner: Member 5.
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Trips')),
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
// TODO(Member 5): Implement this feature in your feature branch.
```

### Create `station_map_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/station_map_screen.dart`

The optional Station? parameter is a future map input. It displays only a name and ownership message; no maps package is needed.

```dart
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
// TODO(Member 3): Display station using Google Maps after validating coordinates.
```

### Create `result_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/result_screen.dart`

The constructor receives the shared TripResult. The page displays a labeled demo and a reusable summary, not calculated travel information.

```dart
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
```

### Create `home_screen.dart`

**File path:** `cairo_metro_guide/lib/screens/home_screen.dart`

A StatelessWidget is enough because the home shell does not change selection state. ListView allows scrolling on small phones. Callbacks open pages or show a SnackBar. The hard-coded TripResult only previews navigation.

```dart
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
              onLocationPressed: () => _openScreen(
                context, StationMapScreen(station: start)),
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
              onLocationPressed: () => _openScreen(
                context, StationMapScreen(station: destination)),
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
            // TODO(Member 1): Implement station selection and swap UI later.
            // TODO(Member 1): Connect completed services after PR review.
            // TODO(Member 5): Coordinate saved selections with Member 1.
          ],
        ),
      ),
    );
  }
}
```

## Step 7 — Create reusable widgets

Widgets accept data and callbacks instead of owning feature logic.

### Create `primary_button.dart`

**File path:** `cairo_metro_guide/lib/widgets/primary_button.dart`

One reusable full-width button keeps appearance consistent. Passing a null onPressed disables it.

```dart
// Owner: Member 1.
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
```

### Create `station_selector.dart`

**File path:** `cairo_metro_guide/lib/widgets/station_selector.dart`

Nullable callbacks let the parent supply behavior. selectedStation?.nameEn reads the name only when the station exists; ?? supplies fallback text. The location icon has its own callback.

```dart
// Owner: Member 1.
import 'package:flutter/material.dart';
import '../models/station.dart';

class StationSelector extends StatelessWidget {
  final String title;
  final Station? selectedStation;
  final VoidCallback? onTap;
  final VoidCallback? onLocationPressed;

  const StationSelector({
    super.key,
    required this.title,
    this.selectedStation,
    this.onTap,
    this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(selectedStation?.nameEn ?? 'Tap to select a station'),
        onTap: onTap,
        trailing: IconButton(
          tooltip: 'Show station location',
          onPressed: onLocationPressed,
          icon: const Icon(Icons.location_on_outlined),
        ),
      ),
    );
  }
}
```

### Create `trip_summary_card.dart`

**File path:** `cairo_metro_guide/lib/widgets/trip_summary_card.dart`

The widget accepts the shared model but leaves calculated fields marked Under development, avoiding false fares or time estimates.

```dart
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
```

## Step 8 — Add the theme

One simple Material theme is sufficient for the team base.

### Create `app_colors.dart`

**File path:** `cairo_metro_guide/lib/theme/app_colors.dart`

Named Color constants keep basic colors in one place.

```dart
// Owner: Member 1.
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF176B53);
  static const Color background = Color(0xFFF5F7F6);
}
```

### Create `app_theme.dart`

**File path:** `cairo_metro_guide/lib/theme/app_theme.dart`

ThemeData creates a consistent Material theme. The seed color generates its color scheme.

```dart
// Owner: Member 1.
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
  );
}
```

## Step 9 — Connect the application and navigation

The home screen’s `_openScreen` uses:

```dart
Navigator.push<void>(
  context,
  MaterialPageRoute<void>(builder: (context) => screen),
);
```

Navigator maintains a stack of pages. push adds a new page above Home.
MaterialPageRoute builds that page with Material navigation behavior. The AppBar
back arrow pops it, revealing Home again. The void type means no return value is
expected. No routing package is required. See the
[official navigation recipe](https://docs.flutter.dev/cookbook/navigation/navigation-basics).


### Create `main.dart`

**File path:** `cairo_metro_guide/lib/main.dart`

main is the entry point; runApp mounts CairoMetroApp. Keeping setup separate makes the app easier to read and reduces conflicts in this shared file.

```dart
// Owner: Member 1 — application entry point.
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const CairoMetroApp());
}
```

### Create `app.dart`

**File path:** `cairo_metro_guide/lib/app.dart`

MaterialApp owns the app title, theme and first screen. It is separate from business logic and the entry point.

```dart
// Owner: Member 1 — app configuration and integration.
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_constants.dart';

class CairoMetroApp extends StatelessWidget {
  const CairoMetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
```

## Step 10 — Configure and verify the skeleton

Replace the generated pubspec.yaml, analysis_options.yaml and counter test with
the following files. No geolocator, maps, geocoding or preferences dependencies
are needed yet. Add those later in the owning feature PR, coordinating shared
configuration changes with the leader.

After all files are in place:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Expected manual checks: Home appears; station selection and swap show a SnackBar;
Find Route opens a demo result; both location icons open the station placeholder;
Search Place, Nearest Station and Recent Trips open their own pages; Back returns
to Home. No GPS permission prompt or network/API setup should be needed.

This authoring environment has no Flutter or Dart SDK. Source/import consistency
was checked, but compilation, analysis, tests and Android execution remain
unverified until you run these commands locally. Do not treat a code review as a
successful build. If the generated test still mentions MyApp, replace that test
with the supplied widget_test.dart.


### Create `pubspec.yaml`

**File path:** `cairo_metro_guide/pubspec.yaml`

Defines the project name, Dart SDK range and Flutter SDK dependencies. flutter_test is supplied by the Flutter SDK; no external package is required. flutter pub get generates the dependency lockfile.

```yaml
name: cairo_metro_guide
description: Beginner-friendly Cairo Metro team architecture starter.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

### Create `analysis_options.yaml`

**File path:** `cairo_metro_guide/analysis_options.yaml`

Uses SDK analyzer defaults without requiring an external lint package. Replace the generated file too, so it does not refer to an undeclared flutter_lints dependency.

```yaml
# SDK analyzer defaults; no external lint package required for the skeleton.
analyzer:
  exclude:
    - build/**
```

### Create `widget_test.dart`

**File path:** `cairo_metro_guide/test/widget_test.dart`

Replaces Flutter’s generated counter test. It checks that the home shell can reach the placeholders, return, preview the result and show the swap SnackBar. This test is provided but has not run in this workspace.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cairo_metro_guide/app.dart';

void main() {
  testWidgets('Home opens each placeholder and returns', (tester) async {
    await tester.pumpWidget(const CairoMetroApp());
    expect(find.text('Cairo Metro Guide'), findsOneWidget);

    for (final entry in {
      'Search Place': 'This feature will be implemented by Member 5.',
      'Nearest Station': 'This feature will be implemented by Member 4.',
      'Recent Trips': 'This feature will be implemented by Member 5.',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('Find Route'));
    await tester.tap(find.text('Find Route'));
    await tester.pumpAndSettle();
    expect(find.text('Route Result — Demo'), findsOneWidget);
    expect(find.text('Ticket price: Under development'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final mapButton = find.byTooltip('Show station location').first;
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();
    expect(find.text('Station Location'), findsOneWidget);
    expect(find.textContaining('Member 3'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final swapButton = find.byTooltip('Swap stations');
    await tester.ensureVisible(swapButton);
    await tester.tap(swapButton);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
```

## Step 11 — Add README and contribution rules

The README distinguishes the working shell from unimplemented features. CONTRIBUTING defines file ownership, commit conventions and review rules.

### Create `README.md`

**File path:** `cairo_metro_guide/README.md`

Keep this document in the project root so all teammates can read the shared workflow.

````markdown
# Cairo Metro Guide

A beginner-friendly Flutter architecture foundation for a five-person team.
The intended app covers Cairo Metro Lines 1, 2 and 3.

## Current status

The starter includes shared models, five synthetic stations, six screens,
Navigator navigation, reusable widgets, theme and TODO service methods.
Selection and swap buttons show a placeholder message. Find Route opens a dummy
result preview; it does not calculate a trip. Map icons open a placeholder page.

| Planned feature | Status |
| --- | --- |
| Start/destination selection and swap | Under Development |
| Routes, station count, transfers, fares and travel time | Under Development |
| Google Maps and station locations | Under Development |
| GPS and nearest station | Under Development |
| Place/street search and its nearest metro station | Under Development |
| Saved selections and recent trips | Under Development |
| Complete verified metro network | Under Development |

## Technologies

Flutter, Dart, Material widgets, Navigator, Git and GitHub. No extra runtime
packages are needed for this architecture. geolocator, google_maps_flutter,
geocoding and shared_preferences are planned, not installed or implemented.

## How to run

This archive is a source overlay. Flutter's generated Android/iOS/platform
folders are not included. On your own computer:

1. Run `flutter create cairo_metro_guide` in your development folder.
2. Copy the archive's cairo_metro_guide folder contents into that generated
   project, replacing matching files. Keep the generated platform folders,
   .metadata and .gitignore. Replace the generated counter widget test too.
3. In Android Studio choose File → Open and select the project root containing
   pubspec.yaml, not its android subfolder. Enable the Flutter/Dart plugins.
4. In the project terminal run:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Choose a running Android emulator or connected phone. `flutter doctor` helps
identify missing local SDK/device setup. See SETUP_GUIDE.md for all 12 steps and
every source file with its explanation.

## Verification

The authoring workspace has no Flutter/Dart SDK. Local file/import consistency
was checked, but compilation, flutter analyze, flutter test and Android execution
have NOT been run. Run the checks above before the initial commit.

## Folder responsibilities

| Folder | Responsibility |
| --- | --- |
| models/ | Shared data contracts; no widgets, GPS or routing logic |
| data/ | Sample station and connection lists; Member 2 later supplies verified data |
| screens/ | Complete pages that use widgets and eventually call services |
| widgets/ | Small reusable UI pieces |
| services/ | Future route, location, search and storage behavior |
| utils/ | Future calculations and shared constants |
| theme/ | Shared colors and Material appearance |
| test/ | Navigation smoke test; feature tests come with implementations |

## Team responsibilities

| Member | Responsibility and main files | Branch |
| --- | --- | --- |
| 1 — Leader | main.dart, app.dart, models/, widgets/, theme/, home and result screens, navigation, reviews and integration | develop for integration; feature/app-shell for new work |
| 2 — Metro route | data/, route_service.dart, fare_calculator.dart, time_calculator.dart; all lines, branches, connections, transfers | feature/metro-route |
| 3 — Maps | station_map_screen.dart and future map files; coordinate validation with Member 2 | feature/google-map |
| 4 — Location | location_service.dart, nearest_station_screen.dart; GPS, permissions, distance, nearest station | feature/nearest-station |
| 5 — Search & storage | place_search_service.dart, storage_service.dart, place_search_screen.dart, history_screen.dart | feature/place-search-storage |

## Branch strategy

main is the stable release branch. develop is the integration branch. Feature
branches start from develop and merge into develop through reviewed PRs.

## Initial GitHub setup

```bash
git init
git add .
git commit -m "chore: initialize Cairo Metro Flutter architecture"
git branch -M main
```

Create an empty GitHub repository called `cairo_metro_guide`. Do not initialize it
with a README, license or .gitignore, because your local project already supplies
the initial files. Replace YOUR_USERNAME below with your GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/cairo_metro_guide.git
git push -u origin main
git switch -c develop
git push -u origin develop
```

Add the four teammates as repository collaborators in GitHub. The remote is not
configured or pushed by this starter; these commands run on your computer.

## How to create a feature branch and submit a PR

```bash
git clone https://github.com/YOUR_USERNAME/cairo_metro_guide.git
cd cairo_metro_guide
git switch develop
git pull --ff-only origin develop
git switch -c feature/metro-route
flutter pub get
```

Each teammate substitutes their assigned branch. Only the branch owner creates
that feature branch; after it exists remotely, use `git switch --track
origin/feature/metro-route` on another machine.

After implementing and checking one feature:

```bash
dart format lib test
flutter analyze
flutter test
flutter run
git add .
git commit -m "feat: implement metro route calculation"
git push -u origin feature/metro-route
```

On GitHub choose **Pull requests → New pull request**, set **base: develop** and
**compare: feature/metro-route**. Describe the change, checks, and any shared-file
changes, then request the leader's review. The leader checks and merges the PR.
Once integration is stable, open another PR from `develop` into `main`.

To bring new integration changes into an existing feature branch, first commit
your current work, then run:

```bash
git fetch origin
git merge origin/develop
```

If Git reports conflicts, open each conflicting file, agree on the intended
content with its owner, remove conflict markers, run the checks, `git add` the
resolved files, `git commit`, and push again. Do not force-push to resolve conflicts.
````

### Create `CONTRIBUTING.md`

**File path:** `cairo_metro_guide/CONTRIBUTING.md`

Keep this document in the project root so all teammates can read the shared workflow.

````markdown
# Contributing to Cairo Metro Guide

- Never push directly to main after initial setup.
- Pull develop before creating a feature branch.
- One feature per branch; merge through a Pull Request into develop.
- Use clear commit messages.
- Discuss changes to another member's files before editing them.
- Discuss shared model changes with Member 1 and every affected member first.
- Coordinate pubspec.yaml, pubspec.lock, Android/iOS configuration, permissions,
  and future API setup with Member 1; these are shared files too.
- Commit pubspec.lock for this application after flutter pub get.
- Run dart format lib test, flutter analyze, flutter test and the app before a PR.
- Resolve errors before requesting merge. State any checks you could not run.
- Team leader reviews PRs; release develop to main through a separate PR.
- Do not commit build output, local SDK paths, credentials or private API secrets.
- Keep dummy data clearly labeled until verified data replaces it.

## Ownership

| Member | Responsibility and main files | Branch |
| --- | --- | --- |
| 1 — Leader | main.dart, app.dart, models/, widgets/, theme/, home and result screens, navigation, reviews and integration | develop for integration; feature/app-shell for new work |
| 2 — Metro route | data/, route_service.dart, fare_calculator.dart, time_calculator.dart; all lines, branches, connections, transfers | feature/metro-route |
| 3 — Maps | station_map_screen.dart and future map files; coordinate validation with Member 2 | feature/google-map |
| 4 — Location | location_service.dart, nearest_station_screen.dart; GPS, permissions, distance, nearest station | feature/nearest-station |
| 5 — Search & storage | place_search_service.dart, storage_service.dart, place_search_screen.dart, history_screen.dart | feature/place-search-storage |

Member 3 should propose coordinate corrections to Member 2 instead of editing
the shared station data concurrently. Member 5 should reuse Member 4's future
distance/nearest-station interface. Agree on that interface before integration.

## Commit prefixes

| Prefix | Purpose | Example |
| --- | --- | --- |
| feat: | New feature | feat: add station map |
| fix: | Bug fix | fix: handle denied location permission |
| refactor: | Restructure without changing behavior | refactor: improve station model |
| docs: | Documentation | docs: update README |
| test: | Tests | test: cover route transfers |
| chore: | Setup or maintenance | chore: update project configuration |

## Feature branch and PR workflow

```bash
git clone https://github.com/YOUR_USERNAME/cairo_metro_guide.git
cd cairo_metro_guide
git switch develop
git pull --ff-only origin develop
git switch -c feature/metro-route
flutter pub get
```

Each teammate substitutes their assigned branch. Only the branch owner creates
that feature branch; after it exists remotely, use `git switch --track
origin/feature/metro-route` on another machine.

After implementing and checking one feature:

```bash
dart format lib test
flutter analyze
flutter test
flutter run
git add .
git commit -m "feat: implement metro route calculation"
git push -u origin feature/metro-route
```

On GitHub choose **Pull requests → New pull request**, set **base: develop** and
**compare: feature/metro-route**. Describe the change, checks, and any shared-file
changes, then request the leader's review. The leader checks and merges the PR.
Once integration is stable, open another PR from `develop` into `main`.

To bring new integration changes into an existing feature branch, first commit
your current work, then run:

```bash
git fetch origin
git merge origin/develop
```

If Git reports conflicts, open each conflicting file, agree on the intended
content with its owner, remove conflict markers, run the checks, `git add` the
resolved files, `git commit`, and push again. Do not force-push to resolve conflicts.
````

## Step 12 — Initialize Git and GitHub branches

```bash
git init
git add .
git commit -m "chore: initialize Cairo Metro Flutter architecture"
git branch -M main
```

Create an empty GitHub repository called `cairo_metro_guide`. Do not initialize it
with a README, license or .gitignore, because your local project already supplies
the initial files. Replace YOUR_USERNAME below with your GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/cairo_metro_guide.git
git push -u origin main
git switch -c develop
git push -u origin develop
```

Add the four teammates as repository collaborators in GitHub. The remote is not
configured or pushed by this starter; these commands run on your computer.

| Member | Responsibility and main files | Branch |
| --- | --- | --- |
| 1 — Leader | main.dart, app.dart, models/, widgets/, theme/, home and result screens, navigation, reviews and integration | develop for integration; feature/app-shell for new work |
| 2 — Metro route | data/, route_service.dart, fare_calculator.dart, time_calculator.dart; all lines, branches, connections, transfers | feature/metro-route |
| 3 — Maps | station_map_screen.dart and future map files; coordinate validation with Member 2 | feature/google-map |
| 4 — Location | location_service.dart, nearest_station_screen.dart; GPS, permissions, distance, nearest station | feature/nearest-station |
| 5 — Search & storage | place_search_service.dart, storage_service.dart, place_search_screen.dart, history_screen.dart | feature/place-search-storage |

```bash
git clone https://github.com/YOUR_USERNAME/cairo_metro_guide.git
cd cairo_metro_guide
git switch develop
git pull --ff-only origin develop
git switch -c feature/metro-route
flutter pub get
```

Each teammate substitutes their assigned branch. Only the branch owner creates
that feature branch; after it exists remotely, use `git switch --track
origin/feature/metro-route` on another machine.

After implementing and checking one feature:

```bash
dart format lib test
flutter analyze
flutter test
flutter run
git add .
git commit -m "feat: implement metro route calculation"
git push -u origin feature/metro-route
```

On GitHub choose **Pull requests → New pull request**, set **base: develop** and
**compare: feature/metro-route**. Describe the change, checks, and any shared-file
changes, then request the leader's review. The leader checks and merges the PR.
Once integration is stable, open another PR from `develop` into `main`.

To bring new integration changes into an existing feature branch, first commit
your current work, then run:

```bash
git fetch origin
git merge origin/develop
```

If Git reports conflicts, open each conflicting file, agree on the intended
content with its owner, remove conflict markers, run the checks, `git add` the
resolved files, `git commit`, and push again. Do not force-push to resolve conflicts.


## Final source tree

Platform folders such as android/ and ios/ are generated by flutter create and retained locally. This archive supplies these files:

```text
cairo_metro_guide/
  CONTRIBUTING.md
  README.md
  SETUP_GUIDE.md
  analysis_options.yaml
  lib/app.dart
  lib/data/metro_data.dart
  lib/main.dart
  lib/models/metro_connection.dart
  lib/models/station.dart
  lib/models/trip_result.dart
  lib/screens/history_screen.dart
  lib/screens/home_screen.dart
  lib/screens/nearest_station_screen.dart
  lib/screens/place_search_screen.dart
  lib/screens/result_screen.dart
  lib/screens/station_map_screen.dart
  lib/services/location_service.dart
  lib/services/place_search_service.dart
  lib/services/route_service.dart
  lib/services/storage_service.dart
  lib/theme/app_colors.dart
  lib/theme/app_theme.dart
  lib/utils/app_constants.dart
  lib/utils/fare_calculator.dart
  lib/utils/time_calculator.dart
  lib/widgets/primary_button.dart
  lib/widgets/station_selector.dart
  lib/widgets/trip_summary_card.dart
  pubspec.yaml
  test/widget_test.dart
```

Sources: [Flutter project creation](https://docs.flutter.dev/reference/create-new-app), [Navigator](https://api.flutter.dev/flutter/widgets/Navigator-class.html).
