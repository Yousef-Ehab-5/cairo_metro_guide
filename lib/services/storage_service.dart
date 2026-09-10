// Owner: Member 5.
import '../models/station.dart';
import '../models/trip_result.dart';

class StorageService {
  Future<void> saveLastTrip({
    required Station start,
    required Station destination,
  }) async {

  }

  Future<void> loadLastTrip() async {

  }

  Future<void> saveRecentTrip(TripResult trip) async {

  }

  Future<List<TripResult>> loadRecentTrips() async {

    return [];
  }
}
