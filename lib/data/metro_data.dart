// Owner: Member 2.
import '../models/station.dart';
import '../models/metro_connection.dart';

// TODO(Member 2): Replace this sample data with the complete verified
// Cairo Metro Lines 1, 2 and 3 data, including branches and connections.
// DEMO ONLY: names, line assignments and coordinates are synthetic.
// Coordinates 0, 0 are placeholders and MUST NOT be used for maps or GPS.
// TODO(Member 3): Validate every real station coordinate with Member 2.
const List<Station> metroStations = [
  Station(
      id: 'demo_a',
      nameEn: 'Demo Station A',
      nameAr: 'محطة تجريبية أ',
      lines: [1],
      latitude: 0,
      longitude: 0),
  Station(
      id: 'demo_b',
      nameEn: 'Demo Station B',
      nameAr: 'محطة تجريبية ب',
      lines: [1],
      latitude: 0,
      longitude: 0),
  Station(
      id: 'demo_c',
      nameEn: 'Demo Interchange C',
      nameAr: 'محطة تبادل تجريبية ج',
      lines: [1, 2],
      latitude: 0,
      longitude: 0),
  Station(
      id: 'demo_d',
      nameEn: 'Demo Station D',
      nameAr: 'محطة تجريبية د',
      lines: [2],
      latitude: 0,
      longitude: 0),
  Station(
      id: 'demo_e',
      nameEn: 'Demo Station E',
      nameAr: 'محطة تجريبية هـ',
      lines: [3],
      latitude: 0,
      longitude: 0),
];

// TODO(Member 2): Add verified neighboring-station connections.
const List<MetroConnection> metroConnections = [];
