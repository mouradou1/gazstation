import 'dart:async';

import '../../../fuel_summary/domain/entities/fuel_summary.dart';
import '../../../pumps_dashboard/domain/entities/pump.dart';
import '../../domain/entities/gas_station.dart';
import '../../domain/repositories/gas_station_repository.dart';
import '../dummy_stations.dart';
import '../models/remote_gas_station_models.dart';

class DummyGasStationRepository implements GasStationRepository {
  DummyGasStationRepository({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;

  Future<T> _withDelay<T>(T Function() body) async {
    if (!delay.isNegative && delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }
    return body();
  }

  @override
  Future<List<GasStation>> fetchStationsList({bool forceRefresh = false}) {
    return _withDelay(() => dummyStations);
  }

  @override
  Future<GasStation?> fetchStationDetails(
    String id, {
    bool forceRefresh = false,
  }) {
    return _withDelay(() {
      try {
        return dummyStations.firstWhere((station) => station.id == id);
      } on StateError {
        return null;
      }
    });
  }

  @override
  Future<FuelTank?> fetchTankById(
    String stationId,
    String tankId, {
    bool forceRefresh = false,
  }) {
    return _withDelay(() {
      try {
        final station = dummyStations.firstWhere(
          (station) => station.id == stationId,
        );
        return station.tanks.firstWhere((tank) => tank.id == tankId);
      } on StateError {
        return null;
      }
    });
  }

  @override
  Future<PumpsWithTransactions> fetchPumps(
    String stationId, {
    bool forceRefresh = false,
  }) {
    // On retourne des données factices pour les tests
    return _withDelay(
      () => (
        pumps: const [
          Pump(
            id: 1,
            label: 'Pump 01',
            nozzles: [
              Nozzle(id: 1, label: 'Volet 01', fuelType: 1, volume: 182),
              Nozzle(id: 2, label: 'Volet 02', fuelType: 1, volume: 64),
              Nozzle(id: 4, label: 'Volet 04', fuelType: 2, volume: 32),
            ],
          ),
          Pump(
            id: 2,
            label: 'Pump 02',
            nozzles: [
              Nozzle(id: 3, label: 'Volet 03', fuelType: 1, volume: 8),
              Nozzle(id: 5, label: 'Volet 05', fuelType: 1, volume: 0),
            ],
          ),
          Pump(
            id: 3,
            label: 'Pump 03',
            nozzles: [
              Nozzle(id: 6, label: 'Volet 06', fuelType: 2, volume: 0),
              Nozzle(id: 7, label: 'Volet 07', fuelType: 2, volume: 0),
            ],
          ),
        ],
        transactions: const <PumpTransactionDto>[],
      ),
    );
  }

  @override
  Future<List<FuelSummary>> fetchFuelSummary(
    String stationId, {
    bool forceRefresh = false,
  }) {
    return _withDelay(
      () => const [
        FuelSummary(
          fuelTypeName: 'DZL',
          totalCapacityLiters: 75000,
          realVolumeLiters: 70235,
          theoreticalVolumeLiters: 71814,
        ),
        FuelSummary(
          fuelTypeName: 'ESS',
          totalCapacityLiters: 65000,
          realVolumeLiters: 15000,
          theoreticalVolumeLiters: 35104,
        ),
        FuelSummary(
          fuelTypeName: 'GPL',
          totalCapacityLiters: 35000,
          realVolumeLiters: 3500,
          theoreticalVolumeLiters: 30138,
        ),
      ],
    );
  }
}
