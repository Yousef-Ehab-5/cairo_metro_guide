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
