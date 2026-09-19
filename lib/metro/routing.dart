import 'network.dart';

enum Passenger {
  regular,
  senior,
  disability,
}

extension PassengerLabel on Passenger {
  String get label {
    switch (this) {
      case Passenger.regular:
        return 'Regular';
      case Passenger.senior:
        return 'Senior 60+';
      case Passenger.disability:
        return 'Disability';
    }
  }
}

enum RoutePreference {
  fewestStops,
  fewestChanges,
}

extension RoutePreferenceLabel on RoutePreference {
  String get label {
    switch (this) {
      case RoutePreference.fewestStops:
        return 'Fewest stops';
      case RoutePreference.fewestChanges:
        return 'Fewest interchanges';
    }
  }

  String get description {
    switch (this) {
      case RoutePreference.fewestStops:
        return 'Fewest stops, then fewest interchanges.';
      case RoutePreference.fewestChanges:
        return 'Fewest interchanges, then fewest stops.';
    }
  }
}

// Your supplied fare table, preserved exactly.
// These values are not independently verified current fares.
int calculateFare(int stationCount, Passenger passenger) {
  if (stationCount < 1) {
    throw ArgumentError('Station count must be positive.');
  }

  if (passenger == Passenger.disability) {
    return 5;
  }

  final band = stationCount <= 9
      ? 0
      : stationCount <= 16
      ? 1
      : stationCount <= 23
      ? 2
      : 3;

  const regular = [10, 12, 15, 20];
  const senior = [5, 6, 8, 10];

  return passenger == Passenger.senior ? senior[band] : regular[band];
}

class JourneyLeg {
  final int line;
  final String service;
  final String direction;
  final List<String> stationIds;

  JourneyLeg({
    required this.line,
    required this.service,
    required this.direction,
    required this.stationIds,
  });

  int get stops => stationIds.length - 1;
}

class Journey {
  final String start;
  final String destination;
  final Passenger passenger;
  final RoutePreference preference;
  final List<String> stationIds;
  final List<JourneyLeg> legs;

  Journey({
    required this.start,
    required this.destination,
    required this.passenger,
    this.preference = RoutePreference.fewestChanges,
    required this.stationIds,
    required this.legs,
  });

  int get stops => stationIds.length - 1;

  int get stationCount => stationIds.length;

  int get changes => legs.isEmpty ? 0 : legs.length - 1;

  // App convention: fare count includes both endpoints.
  int get fare => stops == 0 ? 0 : calculateFare(stationCount, passenger);

  // Estimate: 2.5 minutes per stop plus 5 minutes per interchange.
  // Excludes initial waiting time and live delays.
  int get estimatedMinutes => (stops * 2.5 + changes * 5).ceil();

  // Examples: "45 min", "1 hr", "1 hr 40 min".
  String get estimatedTimeLabel {
    final total = estimatedMinutes;

    if (total < 60) {
      return '$total min';
    }

    final hours = total ~/ 60;
    final minutes = total % 60;

    if (minutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $minutes min';
  }
}

class _Cost implements Comparable<_Cost> {
  final int stops;
  final int changes;
  final RoutePreference preference;

  const _Cost(this.stops, this.changes, this.preference);

  @override
  int compareTo(_Cost other) {
    if (preference == RoutePreference.fewestChanges) {
      // Prefer fewer interchanges, then fewer stops.
      final byChanges = changes.compareTo(other.changes);

      if (byChanges != 0) {
        return byChanges;
      }

      return stops.compareTo(other.stops);
    }

    // Prefer fewer stops, then fewer interchanges.
    final byStops = stops.compareTo(other.stops);

    if (byStops != 0) {
      return byStops;
    }

    return changes.compareTo(other.changes);
  }
}

class _State {
  final String station;
  final String service;

  const _State(this.station, this.service);

  String get key => '$station|$service';
}

class _Previous {
  final String stateKey;
  final TrackEdge edge;

  const _Previous(this.stateKey, this.edge);
}

class RoutePlanner {
  final MetroNetwork network;

  RoutePlanner(this.network);

  Journey find({
    required String start,
    required String destination,
    required Passenger passenger,
    RoutePreference preference = RoutePreference.fewestChanges,
  }) {
    if (!network.stations.containsKey(start) ||
        !network.stations.containsKey(destination)) {
      throw ArgumentError('Choose valid start and destination stations.');
    }

    if (start == destination) {
      return Journey(
        start: start,
        destination: destination,
        passenger: passenger,
        preference: preference,
        stationIds: [start],
        legs: [],
      );
    }

    final initial = _State(start, '');

    final states = <String, _State>{
      initial.key: initial,
    };

    final costs = <String, _Cost>{
      initial.key: _Cost(0, 0, preference),
    };

    final previous = <String, _Previous>{};
    final open = <String>{initial.key};
    final settled = <String>{};

    String? destinationKey;

    while (open.isNotEmpty) {
      // Choose the best available state using the selected preference.
      final currentKey = open.reduce(
            (a, b) => costs[a]!.compareTo(costs[b]!) <= 0 ? a : b,
      );

      open.remove(currentKey);

      if (!settled.add(currentKey)) {
        continue;
      }

      final current = states[currentKey]!;
      final currentCost = costs[currentKey]!;

      if (current.station == destination) {
        destinationKey = currentKey;
        break;
      }

      for (final edge in network.graph[current.station]!) {
        final next = _State(edge.to, edge.service);

        if (settled.contains(next.key)) {
          continue;
        }

        // Initial boarding is not an interchange.
        // Switching between Line 3 services also counts as a change.
        final changing =
            current.service.isNotEmpty && current.service != edge.service;

        final candidate = _Cost(
          currentCost.stops + 1,
          currentCost.changes + (changing ? 1 : 0),
          preference,
        );

        final old = costs[next.key];

        if (old == null || candidate.compareTo(old) < 0) {
          states[next.key] = next;
          costs[next.key] = candidate;
          previous[next.key] = _Previous(currentKey, edge);
          open.add(next.key);
        }
      }
    }

    if (destinationKey == null) {
      throw StateError('No route exists in the available network.');
    }

    // Follow the saved steps backward from destination to start.
    final reversedEdges = <TrackEdge>[];
    var cursor = destinationKey;

    while (cursor != initial.key) {
      final step = previous[cursor]!;
      reversedEdges.add(step.edge);
      cursor = step.stateKey;
    }

    final edges = reversedEdges.reversed.toList();
    final routeIds = <String>[start];
    final legs = <JourneyLeg>[];

    // Group consecutive edges into journey legs.
    for (final edge in edges) {
      routeIds.add(edge.to);

      if (legs.isEmpty ||
          legs.last.service != edge.service ||
          legs.last.direction != edge.direction) {
        legs.add(
          JourneyLeg(
            line: edge.line,
            service: edge.service,
            direction: edge.direction,
            stationIds: [edge.from, edge.to],
          ),
        );
      } else {
        legs.last.stationIds.add(edge.to);
      }
    }

    return Journey(
      start: start,
      destination: destination,
      passenger: passenger,
      preference: preference,
      stationIds: routeIds,
      legs: legs,
    );
  }
}