import 'package:flutter_test/flutter_test.dart';

import 'package:cairo_metro_guide/metro/network.dart';
import 'package:cairo_metro_guide/metro/routing.dart';

void main() {
  late MetroNetwork network;
  late RoutePlanner planner;

  setUp(() {
    network = MetroNetwork();
    planner = RoutePlanner(network);
  });

  test('Network contains 83 unique stations', () {
    expect(network.stations.length, 83);

    for (final entry in network.graph.entries) {
      for (final edge in entry.value) {
        expect(network.stations.containsKey(edge.to), isTrue);
        expect(edge.from, entry.key);
      }
    }
  });

  test('Direct journey needs no train change', () {
    final trip = planner.find(
      start: 'helwan',
      destination: 'ain_helwan',
      passenger: Passenger.regular,
    );

    expect(trip.stops, 1);
    expect(trip.stationCount, 2);
    expect(trip.changes, 0);
    expect(trip.fare, 10);
    expect(trip.legs.single.line, 1);
    expect(trip.legs.single.direction, 'new_el_marg');
  });

  test('Sadat interchange connects Line 1 to Line 2', () {
    final trip = planner.find(
      start: 'saad_zaghloul',
      destination: 'opera',
      passenger: Passenger.regular,
    );

    expect(
      trip.stationIds,
      ['saad_zaghloul', 'sadat', 'opera'],
    );
    expect(trip.changes, 1);
    expect(trip.legs.last.line, 2);
  });

  test('Line 3 branch-to-branch journey changes at Kit Kat', () {
    final trip = planner.find(
      start: 'sudan',
      destination: 'al_tawfikia',
      passenger: Passenger.regular,
    );

    expect(trip.stationIds, ['sudan', 'kit_kat', 'al_tawfikia']);
    expect(trip.changes, 1);
    expect(trip.legs.first.direction, 'adly_mansour');
    expect(trip.legs.last.direction, 'cairo_university');
  });

  test('University branch joins Cairo University correctly', () {
    final trip = planner.find(
      start: 'boulak_el_dakrour',
      destination: 'faisal',
      passenger: Passenger.regular,
    );

    expect(
      trip.stationIds,
      ['boulak_el_dakrour', 'cairo_university', 'faisal'],
    );
    expect(trip.changes, 1);
  });

  test('Same station needs no travel or ticket', () {
    final trip = planner.find(
      start: 'sadat',
      destination: 'sadat',
      passenger: Passenger.regular,
    );

    expect(trip.stops, 0);
    expect(trip.changes, 0);
    expect(trip.fare, 0);
    expect(trip.estimatedMinutes, 0);
  });

  test('Fare boundaries preserve supplied regular values', () {
    expect(calculateFare(9, Passenger.regular), 10);
    expect(calculateFare(10, Passenger.regular), 12);
    expect(calculateFare(16, Passenger.regular), 12);
    expect(calculateFare(17, Passenger.regular), 15);
    expect(calculateFare(23, Passenger.regular), 15);
    expect(calculateFare(24, Passenger.regular), 20);
  });

  test('Senior and disability fares preserve supplied values', () {
    expect(calculateFare(9, Passenger.senior), 10);
    expect(calculateFare(10, Passenger.senior), 6);
    expect(calculateFare(17, Passenger.senior), 7);
    expect(calculateFare(24, Passenger.senior), 8);
    expect(calculateFare(35, Passenger.disability), 5);
  });
}