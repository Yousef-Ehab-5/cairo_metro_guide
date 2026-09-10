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
