import 'package:gazstation/features/home/domain/entities/gas_station.dart';

abstract class GasStationRepository {
  Future<List<GasStation>> fetchStations({bool forceRefresh = false});
  Future<GasStation?> fetchStationById(String id, {bool forceRefresh = false});
  Future<GasStation> fetchStationDetails(String id);
  Future<FuelTank?> fetchTankById(
    String stationId,
    String tankId, {
    bool forceRefresh = false,
  });
}
