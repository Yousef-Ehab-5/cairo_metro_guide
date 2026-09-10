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


