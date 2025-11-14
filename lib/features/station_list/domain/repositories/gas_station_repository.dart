import '../../data/repositories/remote_gas_station_repository.dart';
import '../../../fuel_summary/domain/entities/fuel_summary.dart';
import '../../../pumps_dashboard/domain/entities/pump.dart';
import '../entities/gas_station.dart';

export '../../data/repositories/remote_gas_station_repository.dart'
    show PumpsWithTransactions;

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
  Future<PumpsWithTransactions> fetchPumps(
    String stationId, {
    bool forceRefresh = false,
  });
  Future<List<FuelSummary>> fetchFuelSummary(
    String stationId, {
    bool forceRefresh = false,
  });
}
