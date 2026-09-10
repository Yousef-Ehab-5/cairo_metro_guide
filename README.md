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
