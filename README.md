# Cairo Metro Guide 🚇

A Flutter application for planning journeys across Cairo Metro Lines 1, 2 and 3. Users can select stations, calculate a route, see train changes and directions, estimate fares and journey time, and revisit saved trips.

Built as a learning project by a team of five developers, led by **Yousef Ehab**.

> This README describes the `lib/metro/` implementation developed for this project. Android emulator execution has been reported working by the team leader. Automated test results, iOS execution and production readiness are not claimed here.

## Contents

- [Features](#features)
- [Network, fares and estimates](#network-fares-and-estimates)
- [Project structure](#project-structure)
- [What each file does](#what-each-file-does)
- [How the application works](#how-the-application-works)
- [Setup and running](#setup-and-running)
- [Using the app](#using-the-app)
- [How to make common changes](#how-to-make-common-changes)
- [Team responsibilities](#team-responsibilities)
- [Git and GitHub workflow](#git-and-github-workflow)
- [Testing and troubleshooting](#testing-and-troubleshooting)
- [Limitations and next improvements](#limitations-and-next-improvements)
- [Data, privacy and references](#data-privacy-and-references)

## Features

| Feature | Current behavior |
|---|---|
| Station selection | Search the station list and choose start and destination |
| Swap | Exchange the selected endpoints |
| Route calculation | Find a route with the fewest traveled stops; break ties using fewer train changes |
| Route details | Show station sequence, train lines, terminal directions, boarding and exit stations |
| Interchanges | Show where to change between trains, including a Line 3 branch change |
| Passenger categories | Regular, senior and disability categories |
| Fare calculation | Apply the project's supplied fare configuration |
| Estimated time | Calculate a simple estimate from stops and train changes |
| Maps | Open Google Maps externally for a station or a coordinate |
| GPS | Request the current location when the nearest-station page is opened or refreshed |
| Place search | Search places/streets in the configured Greater Cairo area using Photon |
| Nearby stations | Rank returned OpenStreetMap subway station features by straight-line distance |
| Saved selections | Restore start, destination and passenger category from local storage |
| Recent trips | Save up to 20 entries; reopen and recalculate a journey; clear the list |

Routes, fares and estimates run locally once the app is loaded. GPS, external maps, place search and fetching station coordinates depend on device capabilities, permissions and/or internet access. This is not a guarantee that a web deployment can initially load offline.

## Network, fares and estimates

### Metro network

| Line | Endpoints | Color |
|---|---|---|
| 1 | Helwan ↔ New El-Marg | Blue — `#175CD3` |
| 2 | Shubra El-Kheima ↔ El-Mounib | Red — `#B3261E` |
| 3 | Adly Mansour ↔ Rod El-Farag Corridor / Cairo University | Green — `#13795B` |

The implemented dataset contains **83 unique stations**. Shared stations are stored once and can belong to multiple lines.

| Interchange | Lines |
|---|---|
| Sadat | 1 and 2 |
| Al-Shohadaa | 1 and 2 |
| Nasser | 1 and 3 |
| Attaba | 2 and 3 |
| Cairo University | 2 and 3 |

Line 3 is modeled as two train services sharing Adly Mansour → Kit Kat:

- Rod El-Farag service: shared section, then Sudan → Imbaba → El-Bohy → El-Qawmia → Ring Road → Rod El-Farag Corridor.
- Cairo University service: shared section, then Al-Tawfikia → Wadi El Nile → Gamet El Dowel → Boulak EL Dakrour → Cairo University.

For example, Sudan → Al-Tawfikia travels through Kit Kat and changes train service there. Both legs are on Line 3, but the service change still counts as a train change.

**Road El-Farag on Line 2 and Rod El-Farag Corridor on Line 3 are different stations.** Do not merge their identifiers.

### Fare configuration

These are the values supplied for the project. They have not been established as current official fares.

| Station band | Regular | Senior |
|---|---:|---:|
| 1–9 | EGP 10 | EGP 10 |
| 10–16 | EGP 12 | EGP 6 |
| 17–23 | EGP 15 | EGP 7 |
| 24+ | EGP 20 | EGP 8 |

Disability fare: **EGP 5 flat** for a journey.

The senior table intentionally preserves the supplied values, including the drop from EGP 10 to EGP 6. Confirm the table, category eligibility and actual ticket-counting rules before relying on the result for travel.

Current code conventions:

- `stationCount` includes both endpoints.
- `stops` counts edges traveled, so it equals `stationCount - 1`.
- Transfers do not duplicate a station in the full journey's station list.
- Fare bands use `stationCount`.
- Selecting the same station produces no journey: zero fare and zero estimated minutes.

Example: Helwan → Ain Helwan contains **2 stations** and **1 traveled stop**. Endpoint-inclusive fare counting is an app assumption that still needs verification.

### Time estimate

```text
Estimated minutes = round up(stops × 2.5 + train changes × 5)
```

The estimate excludes initial waiting time, walking to the station and live delays. The planner minimizes stops, not this time estimate, walking distance or ticket price.

## Project structure

```text
cairo_metro_guide/
├── android/
├── ios/
├── web/
├── assets/
│   └── images/
│       └── metro_logo.png                 # If custom icon setup was completed
├── lib/
│   ├── main.dart
│   ├── app.dart
│   └── metro/
│       ├── network.dart
│       ├── routing.dart
│       ├── storage.dart
│       ├── online.dart
│       └── screens.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── flutter_launcher_icons.yaml            # If custom icon setup was completed
├── README.md
└── CONTRIBUTING.md
```

Retain other Flutter-generated platform folders if present. The old `lib/data`, `models`, `screens`, `services`, `theme`, `utils` and `widgets` skeleton folders are not used by this implementation. Remove them only after confirming that they contain no teammate work and have no remaining imports.

## What each file does

### `lib/main.dart` — application entry point

- Calls `WidgetsFlutterBinding.ensureInitialized()` before starting the app.
- Calls `runApp(const CairoMetroApp())`.
- Imports `app.dart`.

Keep startup work here. Avoid adding screens, station lists or route algorithms to this file.

### `lib/app.dart` — application configuration

- Defines `CairoMetroApp`.
- Creates `MaterialApp`, configures its title and Material theme, and hides the debug banner.
- Sets `MetroHome` as the first screen.

Edit this file for app-wide appearance or initial-screen changes. The seed theme color is separate from the individual line colors.

### `lib/metro/network.dart` — stations and connectivity

| Symbol | Purpose |
|---|---|
| `stationId()` | Converts an English name into a readable ID |
| `names()` | Converts multiline station text into an ordered list |
| `line1Names`, `line2Names` | Ordered station names for Lines 1 and 2 |
| `line3SharedNames` | Shared section ending at Kit Kat |
| `line3RodNames`, `line3UniversityNames` | Branch stations after Kit Kat |
| `MetroStation` | Station ID, display name and line memberships |
| `TrainService` | Ordered station IDs for one train service |
| `TrackEdge` | A directed neighbor link with line, service and terminal direction |
| `MetroNetwork` | Builds the canonical station registry and bidirectional graph |
| `metroNetwork` | Shared network instance used by the app |

Add or correct topology here. The graph is built from adjacent entries; an incorrect list order creates an incorrect route connection.

**IDs currently derive from names.** Renaming a station can change its ID and invalidate saved selections or history. Coordinate renames and migrate stored data, or introduce explicit stable IDs before extensive renaming.

### `lib/metro/routing.dart` — route, fare and time logic

| Symbol | Purpose |
|---|---|
| `Passenger` / `PassengerLabel` | Passenger categories and UI labels |
| `calculateFare()` | Selects a fare band or the disability flat fare |
| `JourneyLeg` | One continuous service/direction segment |
| `Journey` | Full journey and computed counts, fare and estimate |
| `_Cost` | Compares traveled stops first, train changes second |
| `_State` | Tracks both current station and current train service |
| `_Previous` | Stores the preceding search step for reconstruction |
| `RoutePlanner.find()` | Searches the graph and constructs the journey legs |

The search is Dijkstra-style with a two-part cost. Keeping the current service in the state allows branch changes to count correctly. The frontier is scanned directly rather than using a priority queue, which keeps the implementation understandable for this small network.

Change fare rules, time assumptions or route preferences here, then update the tests and this README.

### `lib/metro/storage.dart` — local persistence

- `MetroStorage.load()` reads and decodes saved JSON.
- `MetroStorage.save()` serializes app state using `SharedPreferencesAsync`.
- `_pending` queues writes so an older selection does not finish after and replace a newer one.
- The storage key is `cairo_metro_full_app_v1`.

The saved state contains endpoint IDs, passenger category and recent-trip entries. History stores a fare/time snapshot, but tapping an entry recalculates with the current network and configuration.

This is local storage, not an account or cloud backup. Clearing app/browser storage removes it. For browser development, use the same browser, host and port to access the same stored state.

### `lib/metro/online.dart` — external services and location

| Symbol or method | Purpose |
|---|---|
| `MapPlace` | Name, description and coordinates for an online result |
| `NearbyStation` | A place and its distance from the origin |
| `currentLocation()` | Checks location services and requests permission/location |
| `searchPlaces()` | Calls Photon with a Greater Cairo bounding box |
| `_loadSubwayStations()` | Fetches OSM subway station features through Overpass |
| `nearest()` | Sorts returned stations using straight-line distances |
| `openStationMap()` | Opens Google Maps using a station-name query |
| `openPlaceMap()` | Opens Google Maps using coordinates |

The station-coordinate cache is in memory only. It does not become an offline coordinate database.

No Google Maps API key is required for external map links. This implementation does not embed a Google Maps widget.

### `lib/metro/screens.dart` — interactive UI

| Symbol | Purpose |
|---|---|
| `lineColor()` | Blue for Line 1, red for Line 2, green for Line 3 |
| `showMessage()` | Displays feedback with a SnackBar |
| `openMap()` | Opens a station map and reports failures |
| `chooseStation()` / `StationPicker` | Searchable station selection dialog |
| `MetroHome` | Selected endpoints/category, state restoration and feature navigation |
| `JourneyScreen` | Route summary, legs, directions and station map buttons |
| `HistoryPage` | Saved journeys and confirmed history clearing |
| `NearbyPage` | GPS/place lookup, nearby stations and choosing a route start |

Screens use `Navigator.push()` to open a page and `Navigator.pop()` to return a selection or reveal the previous page. `setState()` updates local UI state, and asynchronous operations check `mounted` before updating disposed screens.

This file contains several screens for ease of initial copying. If multiple teammates edit it, split the screen classes into separate files in an agreed refactor first. Do not copy classes into new files while leaving duplicate active definitions behind.

### Supporting files

| File/path | Purpose and editing guidance |
|---|---|
| `test/widget_test.dart` | Currently contains network, route and fare unit tests, despite the filename; it does not establish GPS or full UI correctness |
| `pubspec.yaml` | App metadata, SDK constraints, dependencies and runtime asset declarations |
| `pubspec.lock` | Resolved dependency versions; commit it for this application; do not edit manually |
| `analysis_options.yaml` | Analyzer/lint configuration; keep any lint package references consistent with dependencies |
| `android/app/src/main/AndroidManifest.xml` | Android application settings and permissions |
| `android/gradle.properties` | Android build settings, including the local Kotlin workaround below |
| `android/app/build.gradle.kts` or `.gradle` | App-level Android build configuration; use whichever your project generated |
| `ios/Runner/Info.plist` | iOS app settings and permission descriptions |
| `web/index.html` | Web entry document and browser icon references |
| `web/manifest.json` | Web app installation metadata |
| `assets/images/metro_logo.png` | Source image for custom icons, if added |
| `flutter_launcher_icons.yaml` | Icon generator configuration, if added |
| `CONTRIBUTING.md` | Contribution rules; keep ownership and workflow aligned with this README |

Generated build outputs should not be edited as source code.

## How the application works

1. `main.dart` starts `CairoMetroApp`, which opens `MetroHome`.
2. The network creates unique stations and connects adjacent stops in both directions.
3. Home restores saved selections and history.
4. Selecting or swapping stations updates UI state and saves it locally.
5. Find Route calls `RoutePlanner.find()` with endpoints and passenger category.
6. The planner reconstructs the station sequence and separates train-service legs.
7. Home saves a recent-trip entry and opens the result screen.

For place search, the user selects a Photon result before nearby stations are calculated. For GPS, the device provides the origin. Online station names may differ from the route dataset, so choosing a nearby station as a route start opens the route list for explicit matching; the app does not silently guess a match.

## Setup and running

### Requirements

- Flutter stable and its bundled Dart SDK.
- Android Studio with Flutter/Dart support.
- Android SDK and an emulator or connected Android phone.
- Git and access to the team repository.
- Edge or Chrome for web development.
- A Mac and Xcode for building/running iOS.

Check your environment:

```bash
flutter doctor
flutter doctor --android-licenses
```

### Get the project

Replace `YOUR_USERNAME` with the repository owner's GitHub username:

```bash
git clone https://github.com/YOUR_USERNAME/cairo_metro_guide.git
cd cairo_metro_guide
git switch develop
flutter pub get
```

Open the project root containing `pubspec.yaml` in Android Studio. Do not open only the `android` subfolder.

Dependencies used by the implementation are `shared_preferences`, `geolocator`, `url_launcher` and `http`. A normal clone needs `flutter pub get`; only run the following if these dependencies have not yet been added:

```bash
flutter pub add shared_preferences geolocator url_launcher http
```

### Run on Android

Start a virtual device through Android Studio's Device Manager, wait for its home screen, and select it in the device dropdown. Then run `main.dart`.

Terminal alternative:

```bash
flutter devices
flutter run -d emulator-5554
```

Replace the device ID if `flutter devices` reports a different one.

Add these permissions as direct children of `<manifest>` in `android/app/src/main/AndroidManifest.xml`, preserving the rest of the file:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Follow the installed geolocator version's Android SDK requirements. No background tracking is implemented.

### Run on web

```bash
flutter run -d edge --web-port=8080
```

Or:

```bash
flutter run -d chrome --web-port=8080
```

Use a consistent origin to retain browser selections/history. Allow location when prompted. Deployed browser geolocation requires a secure context such as HTTPS; localhost is intended for development. Online calls remain subject to browser security and the providers' availability.

### iOS preparation

Add inside the main dictionary of `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Find metro stations near your current location.</string>
```

Follow geolocator's foreground-only iOS setup, including the documented `BYPASS_PERMISSION_LOCATION_ALWAYS=1` configuration where applicable. Do not enable background location merely to suppress setup errors. Build and test on a Mac before claiming iOS support has been validated.

### Custom app icon

If configured, the square PNG source is `assets/images/metro_logo.png`, and `flutter_launcher_icons.yaml` sits beside `pubspec.yaml`.

```bash
flutter pub add --dev flutter_launcher_icons
dart run flutter_launcher_icons
```

Restart the app after generating icons; browser icons may require a hard refresh. This changes launcher/browser icons, not the AppBar content. To display the PNG inside a Flutter widget, also declare it under `flutter.assets` in `pubspec.yaml`.

## Using the app

1. Tap Start Station and search for the boarding station.
2. Tap Destination Station and choose the destination.
3. Select the passenger category; use Swap if needed.
4. Tap Find Route and read the line, terminal direction and exit station for each leg.
5. Follow the displayed train-change instructions.
6. Tap a station's map icon to open Google Maps.
7. Use Recent trips to reopen a journey; reopening recalculates its values.
8. Use Nearest station for GPS, or Search place for a street/place origin.

The All stations dialog also sets the selected station as the route start.

## How to make common changes

| Change | Edit | Check afterward |
|---|---|---|
| Line colors | `lineColor()` in `screens.dart` | Route titles and stop icons |
| General app appearance | `app.dart` | Home and every page |
| Station names/order | `network.dart` | IDs, adjacency, interchanges, stored selections |
| New line or branch | Service definitions in `network.dart` | Both travel directions and branch changes |
| Fares/category behavior | `calculateFare()` in `routing.dart` | Every band boundary and category |
| Fare station-count convention | `Journey.fare` and count handling | Boundary tests and UI labels |
| Travel-time estimate | `Journey.estimatedMinutes` | Same-station, direct and transfer journeys |
| Route preference | `_Cost` / `RoutePlanner` | Alternate routes and transfer counts |
| History limit | History trimming in `screens.dart` | Saving, restoring and clearing |
| Saved-data format | `storage.dart` and restore/save code in `screens.dart` | Migration and malformed old data |
| Place provider or lookup area | `online.dart` | No results, timeouts and browser behavior |
| In-app logo | UI plus asset declaration | All target platforms |

## Team responsibilities

| Member | Current ownership | Branch |
|---|---|---|
| 1 — Yousef / integration | `main.dart`, `app.dart`, Home, shared UI, navigation, reviews and integration | `feature/app-shell` |
| 2 — routing | `network.dart`, `routing.dart`, route tests; coordinate result UI edits | `feature/metro-route` |
| 3 — maps | Map-opening methods, map buttons and coordinate validation | `feature/google-map` |
| 4 — location | GPS, nearest-station calculation and GPS UI | `feature/nearest-station` |
| 5 — search/storage | Place search, `storage.dart`, history and persistence UI | `feature/place-search-storage` |

`online.dart` and `screens.dart` currently contain work for several members. **Agree on edits before working in these shared files.** For sustained parallel work, first merge a dedicated refactor that separates screens and online services by feature. All members should then update their branches before continuing.

Coordinate changes to dependencies, platform permissions and shared data contracts with Member 1. Do not overwrite another member's implementation to resolve a merge conflict.

## Git and GitHub workflow

- `main`: stable project state.
- `develop`: integration branch.
- Feature branches: individual work, reviewed through Pull Requests into `develop`.
- Release: reviewed Pull Request from `develop` into `main`.

Start with a clean working tree; preserve any existing work before switching:

```bash
git status
git switch develop
git pull --ff-only origin develop
git switch -c feature/metro-route
```

Substitute your assigned branch. If the branch already exists, switch to it instead of creating it again.

Before opening a PR:

```bash
dart format lib test
flutter analyze
flutter test
git diff --check
git status
```

Run the app on the affected platform, review the changes, then:

```bash
git add .
git commit -m "feat: improve metro route results"
git push -u origin feature/metro-route
```

Create a GitHub PR with **base `develop`**, **compare your feature branch**, and request the leader's review. Explain the behavior change, checks performed and remaining limitations.

To incorporate integration changes, commit your current work first, then:

```bash
git fetch origin
git merge origin/develop
```

If conflicts occur, resolve them with the affected owner, rerun checks, stage the resolved files and complete the merge commit. Do not force-push as a shortcut.

Commit prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:` and `chore:`.

## Testing and troubleshooting

### Automated checks

```bash
flutter analyze
flutter test
```

The provided tests cover registry size/edge references, a direct trip, Sadat interchange, Kit Kat branch changes, Cairo University interchange, identical endpoints and fare boundaries. They have to be run locally; this README does not claim a passing CI run.

### Manual route checks

| Start | Destination | Expected behavior |
|---|---|---|
| Helwan | Ain Helwan | One traveled stop, no change |
| Saad Zaghloul | Opera | Change at Sadat |
| Sudan | Al-Tawfikia | Change service at Kit Kat |
| Boulak EL Dakrour | Faisal | Change at Cairo University |
| Sadat | Sadat | No journey, zero fare/time |

Also test: search with no matches, swap, category changes, restoration after restart, history clearing, denied GPS permission, unavailable location services, online timeouts and map buttons. A working emulator route screen does not verify all these cases.

### Kotlin error: different drive roots

Observed local setup: project on `D:` and package cache on `C:`. The failed Android build reported `this and base files have different roots` while closing Kotlin incremental caches.

The workaround used for this project is to add or update this property in `android/gradle.properties`, keeping the existing configuration:

```properties
kotlin.incremental=false
```

Then stop the run and execute in PowerShell:

```powershell
cd D:\cairo_metro_guide\android
.\gradlew.bat --stop
cd ..
flutter clean
flutter pub get
flutter run -d emulator-5554
```

This disables incremental Kotlin compilation and may slow later builds. It is a workaround for the observed build issue, not a requirement for every teammate's machine. Document it if committed so the team understands its effect.

### Other common problems

| Symptom | What to do |
|---|---|
| `source value 8 is obsolete` warnings | These warnings alone do not mean failure; inspect the final build result |
| `Running Gradle task assembleDebug` | The build is still running; wait for completion or an actual error |
| Emulator not listed | Start it in Device Manager, then run `flutter devices` and `flutter doctor` |
| Location denied | Allow permission in device/browser settings, then retry |
| Emulator location is far from Cairo | Set a Cairo test location using the emulator's location controls; label it as simulated during testing |
| Place/nearby lookup fails | Check connectivity and retry later; public services can time out or throttle |
| Search returns no result | Try a specific name within Greater Cairo and select the correct result |
| Browser selections appear lost | Reuse the same browser and origin, including port; avoid private mode |
| Flutter icon remains | Regenerate icons, restart, and hard-refresh the browser |
| Analyzer reports old placeholder classes | Remove obsolete imports/files and replace the original counter/placeholder test |

Do not disable browser security or TLS checks to make an online request work. If production browser access requires a backend, configure a controlled service endpoint instead.

## Limitations and next improvements

Current limits:

- No live service disruptions, train arrival times or accessibility routing.
- Fare data and endpoint-inclusive counting still need confirmation.
- Nearby results depend on OSM tags and coverage; they are not a verified complete list of all station entrances.
- Straight-line distances do not account for roads, barriers or accessible entrances.
- Station-name map searches can be ambiguous; inspect the result before navigating.
- External map links are used instead of an embedded map.
- Place searches use a Greater Cairo bounding box.
- No accounts, cloud sync or cross-device history.
- iOS execution has not been reported verified.

Suggested next work:

1. Verify fares, counting conventions and network data; record source and effective date.
2. Establish stable IDs independent of display names and add bilingual labels.
3. Validate a station/entrance coordinate dataset and mapping from online results to station IDs.
4. Split shared UI and online-service files for parallel team development.
5. Add widget, storage and online-error tests, then CI checks for PRs.
6. Improve route alternatives and separate walking/waiting estimates.
7. Replace public demo services with appropriate hosted services before significant usage.

These are proposed improvements, not completed features.

## Data, privacy and references

Most station names/order and all fares were supplied for the project. The additional Cairo University branch follows the operator's published opening announcement. This does not independently validate every supplied name, fare or current service condition.

- [Line 3 branch opening announcement — RATP Dev Mobility Cairo](https://www.linkedin.com/posts/mobility-cairo_green-line-3-is-expanding-5-new-stations-activity-7195426804285763584-cemm)
- [Geolocator setup and platform requirements](https://pub.dev/packages/geolocator)
- [Shared preferences](https://pub.dev/packages/shared_preferences)
- [URL launcher](https://pub.dev/packages/url_launcher)
- [HTTP package](https://pub.dev/packages/http)
- [Photon project and public-service limits](https://github.com/komoot/photon)
- [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [OpenStreetMap attribution and license](https://www.openstreetmap.org/copyright)
- [Kotlin compilation and caches](https://kotlinlang.org/docs/gradle-compilation-and-caches.html)

Location is requested for the nearest-station feature. Distance ranking happens locally after fetching the configured area's station features. Place queries are sent to Photon; opening map links sends the selected station query or coordinates to Google Maps. The current app does not implement background location tracking.

Show **© OpenStreetMap contributors** attribution for OSM-based results. If making that attribution clickable in the UI, link it to the OSM copyright page above; do not send an attribution tap to a Google Maps location.

The project is not presented as an official Cairo Metro application. Confirm permission to use any chosen Metro logo before public distribution. An application source-code license has not been selected in this README; add a `LICENSE` file when the team agrees on one.
