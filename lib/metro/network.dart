String stationId(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

List<String> names(String text) {
  return text
      .trim()
      .split('\n')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

final List<String> line1Names = names('''
Helwan
Ain Helwan
Helwan University
Wadi Hof
Hadayek Helwan
El-Maasara
Tora El-Asmant
Kozzika
Tora El-Balad
Sakanat El-Maadi
Maadi
Hadayek El-Maadi
Dar El-Salam
El-Zahraa
Mar Girgis
El-Malek El-Saleh
Al-Sayeda Zeinab
Saad Zaghloul
Sadat
Nasser
Orabi
Al-Shohadaa
Ghamra
El-Demerdash
Manshiet El-Sadr
Kobri El-Qobba
Hammamat El-Qobba
Saray El-Qobba
Hadayeq El-Zaitoun
Helmeyet El-Zaitoun
El-Matareyya
Ain Shams
Ezbet El-Nakhl
El-Marg
New El-Marg
''');

final List<String> line2Names = names('''
Shubra El-Kheima
Kolleyyet El-Zeraa
Mezallat
Khalafawy
St. Teresa
Road El-Farag
Masarra
Al-Shohadaa
Attaba
Mohamed Naguib
Sadat
Opera
Dokki
El Bohoth
Cairo University
Faisal
El Giza
Omm El-Masryeen
Sakiat Mekky
El-Mounib
''');

final List<String> line3SharedNames = names('''
Adly Mansour
El Haykestep
Omar Ibn El-Khattab
Qobaa
Hesham Barakat
El-Nozha
Nadi El-Shams
Alf Maskan
Heliopolis Square
Haroun
Al-Ahram
Koleyet El-Banat
Stadium
Fair Zone
Abbassia
Abdou Pasha
El Geish
Bab El Shaaria
Attaba
Nasser
Maspero
Safaa Hegazy
Kit Kat
''');

final List<String> line3RodNames = names('''
Sudan
Imbaba
El-Bohy
El-Qawmia
Ring Road
Rod El-Farag Corridor
''');

// Additional branch from the operator's Phase 3C announcement.
// Kit Kat already appears at the end of the shared section.
final List<String> line3UniversityNames = names('''
Al-Tawfikia
Wadi El Nile
Gamet El Dowel
Boulak EL Dakrour
Cairo University
''');

class MetroStation {
  final String id;
  final String name;
  final List<int> lines;

  const MetroStation({
    required this.id,
    required this.name,
    required this.lines,
  });
}

class TrainService {
  final String id;
  final int line;
  final List<String> stations;

  TrainService({
    required this.id,
    required this.line,
    required List<String> names,
  }) : stations = List.unmodifiable(names.map(stationId));
}

class TrackEdge {
  final String from;
  final String to;
  final String service;
  final int line;
  final String direction;

  const TrackEdge({
    required this.from,
    required this.to,
    required this.service,
    required this.line,
    required this.direction,
  });
}

class MetroNetwork {
  final Map<String, MetroStation> stations = {};
  final Map<String, List<TrackEdge>> graph = {};

  late final List<TrainService> services;

  MetroNetwork() {
    services = [
      TrainService(id: 'line1', line: 1, names: line1Names),
      TrainService(id: 'line2', line: 2, names: line2Names),
      TrainService(
        id: 'line3_rod',
        line: 3,
        names: [...line3SharedNames, ...line3RodNames],
      ),
      TrainService(
        id: 'line3_university',
        line: 3,
        names: [...line3SharedNames, ...line3UniversityNames],
      ),
    ];

    final stationNames = <String, String>{};

    for (final name in [
      ...line1Names,
      ...line2Names,
      ...line3SharedNames,
      ...line3RodNames,
      ...line3UniversityNames,
    ]) {
      stationNames[stationId(name)] = name;
    }

    for (final entry in stationNames.entries) {
      final memberships = services
          .where((service) => service.stations.contains(entry.key))
          .map((service) => service.line)
          .toSet()
          .toList()
        ..sort();

      stations[entry.key] = MetroStation(
        id: entry.key,
        name: entry.value,
        lines: List.unmodifiable(memberships),
      );
      graph[entry.key] = [];
    }

    for (final service in services) {
      for (var i = 0; i < service.stations.length - 1; i++) {
        final from = service.stations[i];
        final to = service.stations[i + 1];

        graph[from]!.add(
          TrackEdge(
            from: from,
            to: to,
            service: service.id,
            line: service.line,
            direction: service.stations.last,
          ),
        );

        graph[to]!.add(
          TrackEdge(
            from: to,
            to: from,
            service: service.id,
            line: service.line,
            direction: service.stations.first,
          ),
        );
      }
    }
  }

  String name(String id) => stations[id]?.name ?? id;

  List<MetroStation> get sortedStations {
    return stations.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}

// Monorail connections supplied for this project.
// Connection labels do not establish current service availability.
const Map<String, String> monorailConnections = {
  'stadium': 'East of Nile Monorail',
  'wadi_el_nile': 'West of Nile Monorail',
};

final metroNetwork = MetroNetwork();
