import 'package:gazstation/features/home/domain/entities/gas_station.dart';

abstract class GasStationRepository {
  Future<List<GasStation>> fetchStationsList({bool forceRefresh = false});
  Future<GasStation?> fetchStationDetails(
    String id, {
    bool forceRefresh = false,
  });
  Future<FuelTank?> fetchTankById(
    String stationId,
    String tankId, {
    bool forceRefresh = false,
  });
}
