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
